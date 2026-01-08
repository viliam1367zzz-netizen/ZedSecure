package dev.amirzr.flutter_v2ray_client.v2ray.services;

import android.app.Service;
import android.content.Intent;
import android.net.VpnService;
import android.os.Build;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import dev.amirzr.flutter_v2ray_client.v2ray.core.FluxTunCore;
import dev.amirzr.flutter_v2ray_client.v2ray.core.V2rayCoreManager;
import dev.amirzr.flutter_v2ray_client.v2ray.interfaces.V2rayServicesListener;
import dev.amirzr.flutter_v2ray_client.v2ray.utils.AppConfigs;
import dev.amirzr.flutter_v2ray_client.v2ray.utils.V2rayConfig;

import org.json.JSONArray;
import org.json.JSONObject;

public class V2rayVPNService extends VpnService implements V2rayServicesListener {
    private static final String TAG = "V2rayVPNService";
    private ParcelFileDescriptor mInterface;
    private V2rayConfig v2rayConfig;
    private boolean isRunning = false;

    @Override
    public void onCreate() {
        super.onCreate();
        V2rayCoreManager.getInstance().setUpListener(this);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        AppConfigs.V2RAY_SERVICE_COMMANDS startCommand = (AppConfigs.V2RAY_SERVICE_COMMANDS) intent.getSerializableExtra("COMMAND");
        if (startCommand.equals(AppConfigs.V2RAY_SERVICE_COMMANDS.START_SERVICE)) {
            v2rayConfig = (V2rayConfig) intent.getSerializableExtra("V2RAY_CONFIG");
            if (v2rayConfig == null) {
                this.onDestroy();
            }
            if (V2rayCoreManager.getInstance().isV2rayCoreRunning()) {
                V2rayCoreManager.getInstance().stopCore();
            }
            if (V2rayCoreManager.getInstance().startCore(v2rayConfig)) {
                Log.d(TAG, "onStartCommand success => v2ray core started.");
            } else {
                this.onDestroy();
            }
        } else if (startCommand.equals(AppConfigs.V2RAY_SERVICE_COMMANDS.STOP_SERVICE)) {
            V2rayCoreManager.getInstance().stopCore();
            AppConfigs.V2RAY_CONFIG = null;
            stopAllProcess();
        } else if (startCommand.equals(AppConfigs.V2RAY_SERVICE_COMMANDS.MEASURE_DELAY)) {
            new Thread(() -> {
                Intent sendB = new Intent("CONNECTED_V2RAY_SERVER_DELAY");
                sendB.putExtra("DELAY", String.valueOf(V2rayCoreManager.getInstance().getConnectedV2rayServerDelay()));
                sendBroadcast(sendB);
            }, "MEASURE_CONNECTED_V2RAY_SERVER_DELAY").start();
        } else {
            this.onDestroy();
        }
        return START_STICKY;
    }

    private void stopAllProcess() {
        stopForeground(true);
        isRunning = false;
        
        FluxTunCore.stop();
        
        V2rayCoreManager.getInstance().stopCore();
        try {
            stopSelf();
        } catch (Exception e) {
            Log.e(TAG, "CANT_STOP SELF");
        }
        try {
            if (mInterface != null) {
                mInterface.close();
                mInterface = null;
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to close interface", e);
        }
    }

    private void setup() {
        Intent prepare_intent = prepare(this);
        if (prepare_intent != null) {
            return;
        }
        Builder builder = new Builder();
        builder.setSession(v2rayConfig.REMARK);
        builder.setMtu(1500);
        builder.addAddress("10.1.0.2", 24);

        if (v2rayConfig.BYPASS_SUBNETS == null || v2rayConfig.BYPASS_SUBNETS.isEmpty()) {
            builder.addRoute("0.0.0.0", 0);
        } else {
            for (String subnet : v2rayConfig.BYPASS_SUBNETS) {
                String[] parts = subnet.split("/");
                if (parts.length == 2) {
                    String address = parts[0];
                    int prefixLength = Integer.parseInt(parts[1]);
                    builder.addRoute(address, prefixLength);
                }
            }
        }
        
        try {
            builder.addDisallowedApplication(getPackageName());
            Log.d(TAG, "Excluded self from VPN: " + getPackageName());
        } catch (Exception e) {
            Log.e(TAG, "Failed to exclude self from VPN", e);
        }
        
        if (v2rayConfig.BLOCKED_APPS != null) {
            for (int i = 0; i < v2rayConfig.BLOCKED_APPS.size(); i++) {
                try {
                    builder.addDisallowedApplication(v2rayConfig.BLOCKED_APPS.get(i));
                } catch (Exception e) {
                }
            }
        }
        try {
            JSONObject json = new JSONObject(v2rayConfig.V2RAY_FULL_JSON_CONFIG);
            if (json.has("dns")) {
                JSONObject dnsObject = json.getJSONObject("dns");
                if (dnsObject.has("servers")) {
                    JSONArray serversArray = dnsObject.getJSONArray("servers");
                    for (int i = 0; i < serversArray.length(); i++) {
                        try {
                            Object entry = serversArray.get(i);
                            if (entry instanceof String) {
                                builder.addDnsServer((String) entry);
                            } else if (entry instanceof JSONObject) {
                                JSONObject obj = (JSONObject) entry;
                                if (obj.has("address")) {
                                    builder.addDnsServer(obj.getString("address"));
                                }
                            }
                        } catch (Exception ignored) {
                        }
                    }
                }
            }
        } catch (Exception e) {
            try { builder.addDnsServer("8.8.8.8"); } catch (Exception ignored) {}
            try { builder.addDnsServer("8.8.4.4"); } catch (Exception ignored) {}
        }
        try {
            if (mInterface != null) {
                mInterface.close();
            }
        } catch (Exception e) {
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false);
        }

        try {
            mInterface = builder.establish();
            if (mInterface == null) {
                Log.e(TAG, "Failed to establish VPN interface");
                stopAllProcess();
                return;
            }
            isRunning = true;
            startFluxTun();
        } catch (Exception e) {
            Log.e(TAG, "Failed to establish VPN interface", e);
            stopAllProcess();
        }
    }

    private void startFluxTun() {
        int fd = mInterface.getFd();
        String socksHost = "127.0.0.1";
        int socksPort = v2rayConfig.LOCAL_SOCKS5_PORT;
        int mtu = 1500;
        
        Log.d(TAG, "Starting FluxTun with fd=" + fd + ", socks=" + socksHost + ":" + socksPort);
        
        boolean started = FluxTunCore.start(fd, socksHost, socksPort, mtu, this);
        if (!started) {
            Log.e(TAG, "Failed to start FluxTun");
            stopAllProcess();
        } else {
            Log.d(TAG, "FluxTun started successfully");
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
    }

    @Override
    public void onRevoke() {
        stopAllProcess();
    }

    @Override
    public boolean onProtect(int socket) {
        return protect(socket);
    }

    @Override
    public Service getService() {
        return this;
    }

    @Override
    public void startService() {
        setup();
    }

    @Override
    public void stopService() {
        stopAllProcess();
    }
}
