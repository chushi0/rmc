package com.github.chushi0.gdextensionandroidsensors;

import android.app.Activity;
import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.SystemClock;
import android.view.View;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.Optional;

@SuppressWarnings("unused")
public class GDExtensionAndroidPlugin extends GodotPlugin {
    private SensorManager sensorManager;
    private SensorEventListener gravitySensorListener;
    private SensorEventListener gyroscopeSensorListener;
    private volatile float[] gravitySensorValues = new float[3];
    private volatile long gyroscopeLastTimestamp;
    private volatile float[] gyroscopeRotateAngles;

    public GDExtensionAndroidPlugin(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return BuildConfig.GODOT_PLUGIN_NAME;
    }

    @Override
    public View onMainCreate(Activity activity) {
        View view = super.onMainCreate(activity);

        sensorManager = (SensorManager) activity.getSystemService(Context.SENSOR_SERVICE);
        gravitySensorListener = new SensorEventListener() {
            @Override
            public void onSensorChanged(SensorEvent event) {
                gravitySensorValues = event.values;
                if (gyroscopeRotateAngles == null) {
                    gyroscopeRotateAngles = new float[]{
                            (float) Math.atan(event.values[2] / event.values[1]),
                            (float) Math.atan(event.values[2] / event.values[0]),
                            (float) Math.atan(event.values[1] / event.values[0]),
                    };
                }
            }

            @Override
            public void onAccuracyChanged(Sensor sensor, int accuracy) {
            }
        };
        gyroscopeSensorListener = new SensorEventListener() {
            @Override
            public void onSensorChanged(SensorEvent event) {
                long timestamp = event.timestamp;
                long delta = timestamp - gyroscopeLastTimestamp;
                float[] angles = gyroscopeRotateAngles;
                if (angles == null) {
                    angles = new float[3];
                } else {
                    angles = angles.clone();
                }
                angles[0] += event.values[0] * (delta / 1000000000.0);
                angles[1] += event.values[1] * (delta / 1000000000.0);
                angles[2] += event.values[2] * (delta / 1000000000.0);
                gyroscopeRotateAngles = angles;
                gyroscopeLastTimestamp = timestamp;
            }

            @Override
            public void onAccuracyChanged(Sensor sensor, int accuracy) {
            }
        };

        return view;
    }

    @Override
    public void onMainResume() {
        super.onMainResume();
        gyroscopeLastTimestamp = SystemClock.elapsedRealtimeNanos();
        gyroscopeRotateAngles = null;
        sensorManager.registerListener(gravitySensorListener, sensorManager.getDefaultSensor(Sensor.TYPE_GRAVITY), SensorManager.SENSOR_DELAY_FASTEST);
        sensorManager.registerListener(gyroscopeSensorListener, sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE), SensorManager.SENSOR_DELAY_FASTEST);
    }

    @Override
    public void onMainPause() {
        super.onMainPause();
        sensorManager.unregisterListener(gravitySensorListener);
        sensorManager.unregisterListener(gyroscopeSensorListener);
    }

    @UsedByGodot
    public float gravity_sensor_angle() {
        float[] sensorValues = this.gravitySensorValues;
        if (sensorValues == null) {
            return 0;
        }
        return (float) Math.atan(sensorValues[1] / sensorValues[0]);
    }

    @UsedByGodot
    public float gyroscope_sensor_angle() {
        if (gyroscopeRotateAngles == null) {
            return 0;
        }
        return gyroscopeRotateAngles[2];
    }

    @UsedByGodot
    public void align_gyroscope_sensor() {
        gyroscopeRotateAngles = new float[3];
        gyroscopeLastTimestamp = SystemClock.elapsedRealtimeNanos();
    }
}
