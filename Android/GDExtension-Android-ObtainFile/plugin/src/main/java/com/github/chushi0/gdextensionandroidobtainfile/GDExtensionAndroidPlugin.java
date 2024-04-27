package com.github.chushi0.gdextensionandroidobtainfile;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.net.Uri;
import android.os.SystemClock;
import android.view.View;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOError;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.List;

@SuppressWarnings("unused")
public class GDExtensionAndroidPlugin extends GodotPlugin {

    private static final int REQUEST_OBTAIN_FILE = 0x2A01;

    private String lastCacheFilePath = null;

    public GDExtensionAndroidPlugin(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return BuildConfig.GODOT_PLUGIN_NAME;
    }

    @UsedByGodot
    public void request_open_file() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("*/*");
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

        getActivity().startActivityForResult(intent, REQUEST_OBTAIN_FILE);
    }

    @Override
    public void onMainActivityResult(int requestCode, int resultCode, Intent data) {
        super.onMainActivityResult(requestCode, resultCode, data);
        if (requestCode != REQUEST_OBTAIN_FILE || resultCode != Activity.RESULT_OK || data == null) {
            return;
        }

        Uri uri = data.getData();
        if (uri == null) {
            return;
        }

        List<String> segments = uri.getPathSegments();
        String fileName = segments.get(segments.size() - 1);
        File cacheFile = new File(getActivity().getCacheDir(), fileName);
        cacheFile.getParentFile().mkdirs();

        try (InputStream inputStram = getActivity().getContentResolver().openInputStream(uri);
             OutputStream outputStream = new FileOutputStream(cacheFile)) {
            byte[] buffer = new byte[8192];
            int len;
            while ((len = inputStram.read(buffer)) > 0) {
                outputStream.write(buffer, 0, len);
            }
        } catch (IOException e) {
            if (BuildConfig.DEBUG) {
                e.printStackTrace();
            }
        }

        lastCacheFilePath = cacheFile.getAbsolutePath();
    }

    @UsedByGodot
    public String get_last_cache_file_path() {
        return lastCacheFilePath;
    }

    @UsedByGodot
    public void clear_cache_file_path() {
        new File(lastCacheFilePath).delete();
        lastCacheFilePath = null;
    }
}
