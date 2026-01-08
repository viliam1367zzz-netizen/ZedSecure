package dev.amirzr.flutter_v2ray_client.v2ray.core;

import android.net.VpnService;

public class FluxTunCore {
    
    static {
        System.loadLibrary("fluxtun");
    }
    
    public static native boolean start(int fd, String socksHost, int socksPort, int mtu, VpnService vpnService);
    
    public static native void stop();
    
    public static native boolean isRunning();
    
    public static native long getTxBytes();
    
    public static native long getRxBytes();
}
