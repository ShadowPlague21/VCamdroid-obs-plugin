// Copyright (C) 2022 DEV47APPS, github.com/dev47apps
#pragma once
#define OPT_VERSION           "version"
#define OPT_WIFI_IP           "wifi_ip"
#define OPT_APP_PORT          "app_port"
#define OPT_RESOLUTION_STR    "resolution_str"
#define OPT_VIDEO_FORMAT      "video_format"
#define OPT_CONNECT           "connect"
#define OPT_REFRESH           "refresh"
#define OPT_DEACTIVATE_WNS    "deactivate_wns"
#define OPT_SYNC_AV           "sync_av"
#define OPT_USE_HDR           "allow_hdr"
#define OPT_USE_HW_ACCEL      "allow_hw_accel"
#define OPT_UNBUFFERED_OUT    "unbuffered_output"
#define OPT_IS_ACTIVATED      "activated"
#define OPT_ENABLE_AUDIO      "enable_aduio"
#define OPT_DEVICE_LIST       "device_list"
#define OPT_DEVICE_ID_WIFI    "dev_id_wifi"
#define OPT_ACTIVE_DEV_ID     "cur_dev_id"
#define OPT_ACTIVE_DEV_IP     "cur_dev_ip"
#define OPT_ACTIVE_DEV_TYPE   "cur_dev_type"
#define OPT_UHD_UNLOCK        "uhd_unlock"
#define OPT_DUMMY_SOURCE      "dummy_source"

#define TEXT_DEVICE         obs_module_text("Device")
#define TEXT_REFRESH        obs_module_text("Refresh")
#define TEXT_RESOLUTION     obs_module_text("Resolution")
#define TEXT_VIDEO_FORMAT   obs_module_text("VideoFormat")
#define TEXT_CONNECT        obs_module_text("Activate")
#define TEXT_DEACTIVATE     obs_module_text("Deactivate")
#define TEXT_DWNS           obs_module_text("DeactivateWhenNotShowing")
#define TEXT_USE_WIFI       obs_module_text("UseWiFi")
#define TEXT_ENABLE_AUDIO   obs_module_text("EnableAudio")
#define TEXT_SYNC_AV        obs_module_text("SyncAV")
#define TEXT_USE_HDR        obs_module_text("AllowHDR")
#define TEXT_USE_HW_ACCEL   obs_module_text("AllowHWAccel")
#define TEXT_LATENCY_TOGGLE obs_module_text("LatencyToggle")
#define TEXT_LATENCY_DESCR  obs_module_text("LatencyToolTip")

#define PING_REQ "GET /ping"
#define BATT_REQ "GET /battery HTTP/1.1\r\n\r\n"
#define TALLY_REQ "PUT /v1/tally/%s/ HTTP/1.1\r\n\r\n"
#define AUDIO_REQ "GET /v2/audio"
#define VIDEO_REQ "GET /v5/video/%s/%dx%d/port/%d/os/%s/obs/%s/client/%s/hdr/%d/nonce/%d/"

#define DEFAULT_PORT 4747
#define DROIDCAM_SERVICE_NAME "_droidcamobs._tcp.local."


#ifdef __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-variable"
#endif
static const char* opt_use_wifi = OPT_DEVICE_ID_WIFI;
static const char* localhost_ip = "127.0.0.1";

static const char* VideoFormatNames[][2] = {
    {"AVC/H.264", "avc"},
    {"MJPEG", "jpg"},
    {"HEVC/H.265", "hevc"},
};

static const char* Resolutions[] = {
    // 16:9 Standard
    "1920x1080",
    "1280x720",
    "2560x1440",
    "3840x2160",
    "640x360",
    // 4:3 Presets
    "1920x1440",
    "2880x2160",
    "1600x1200",
    "1440x1080",
    "1280x960",
    "1024x768",
    "640x480",
    // 1:1 Square Presets
    "2160x2160",
    "1440x1440",
    "1080x1080",
    "720x720",
    // 9:16 Vertical Presets
    "1080x1920",
    "720x1280",
    // 21:9 Ultrawide Presets
    "2560x1080",
    "3440x1440",
};

#define RESOLUTION_1080 0

#ifdef __GNUC__
#pragma GCC diagnostic pop
#endif
extern int sscanf(const char*, const char*, ...);

static inline bool ConvertRes(const char *res, int* cx, int* cy)
{
    *cx = 0; *cy = 0;
    return sscanf(res, "%dx%d", cx, cy) == 2;
}

static inline bool ResolutionValid(const char *res, int* cx, int* cy)
{
    const int MIN_DIM = 128;
    const int MAX_DIM = 8192;
    return ConvertRes(res, cx, cy)
        && (*cx >= MIN_DIM && *cy >= MIN_DIM && *cx <= MAX_DIM && *cy <= MAX_DIM);
}

static inline int getResolutionIndex(const char* resolution) {
    for (size_t i = 0; i < ARRAY_LEN(Resolutions); i++) {
        if (strcmp(Resolutions[i], resolution) == 0)
            return (int)i;
    }

    return 0;
}

