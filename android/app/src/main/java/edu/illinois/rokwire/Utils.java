/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package edu.illinois.rokwire;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.location.Location;
import android.text.format.DateUtils;
import android.util.Log;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

import com.google.android.gms.maps.model.BitmapDescriptorFactory;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;
import com.google.maps.android.ui.IconGenerator;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.nio.ByteBuffer;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.Formatter;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.lang.Exception;

import androidx.core.content.ContextCompat;
import androidx.security.crypto.MasterKeys;
import androidx.security.crypto.EncryptedSharedPreferences;
import edu.illinois.rokwire.maps.MapMarkerViewType;

import static android.view.View.GONE;
import static android.view.View.VISIBLE;

public class Utils {

    public static void showDialog(Context context, String title, String message,
                                  DialogInterface.OnClickListener positiveListener, String positiveText,
                                  DialogInterface.OnClickListener negativeListener, String negativeText,
                                  boolean cancelable) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle(title);
        builder.setMessage(message);
        builder.setCancelable(cancelable);

        if (positiveListener != null)
            builder.setPositiveButton(positiveText, positiveListener);

        if (negativeListener != null)
            builder.setNegativeButton(negativeText, negativeListener);

        AlertDialog alertDialog = builder.create();
        alertDialog.show();
    }

    public static class DateTime {

        static Date getDateTime(String dateTimeString) {
            if (dateTimeString == null || dateTimeString.isEmpty()) {
                return null;
            }
            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault());
            Date dateTime = null;
            try {
                dateTime = dateFormat.parse(dateTimeString);
            } catch (ParseException e) {
                Log.e("Error", "Failed to parse '" + dateTimeString + "' to date time");
                e.printStackTrace();
            }
            return dateTime;
        }

        static String formatEventTime(Context context, Date dateTime) {
            if (dateTime == null) {
                return null;
            }
            Calendar calendarDate = Calendar.getInstance();
            int minutes = calendarDate.get(Calendar.MINUTE);
            Calendar today = Calendar.getInstance();
            calendarDate.setTime(dateTime);
            boolean zeroMins = (minutes == 0);
            boolean currentYear = calendarDate.get(Calendar.YEAR) == today.get(Calendar.YEAR);
            final String defaultStringFormat = String.format("%sMMM dd h%s a", (currentYear ? "" : "yy, "), (zeroMins ? "" : ":mm"));
            String defaultValue = new SimpleDateFormat(defaultStringFormat, Locale.getDefault()).format(dateTime);
            SimpleDateFormat dateFormat;
            String datePrefix;
            String timeSuffix;
            String format = zeroMins ? "h a" : "h:mm a";
            dateFormat = new SimpleDateFormat(format, Locale.getDefault());
            timeSuffix = dateFormat.format(dateTime);
            boolean isToday = DateUtils.isToday(dateTime.getTime());
            if (isToday) {
                datePrefix = context.getString(R.string.today) + " " + context.getString(R.string.at);
            } else if (calendarDate.after(today)) {
                int dateDayOfYear = calendarDate.get(Calendar.DAY_OF_YEAR);
                int todayDateOfYear = today.get(Calendar.DAY_OF_YEAR);
                int dateDiff = (dateDayOfYear - todayDateOfYear);
                boolean sameYear = (today.get(Calendar.YEAR) == calendarDate.get(Calendar.YEAR));
                if ((dateDiff == 1) && sameYear) {
                    datePrefix = context.getString(R.string.tomorrow) + " " + context.getString(R.string.at);
                } else if ((dateDiff < 7) && sameYear) {
                    dateFormat = new SimpleDateFormat("EEEE", Locale.getDefault());
                    datePrefix = dateFormat.format(dateTime) + " " + context.getString(R.string.at);
                } else {
                    return defaultValue;
                }
            } else {
                return defaultValue;
            }
            return String.format("%s %s", datePrefix, timeSuffix);
        }

        public static long getCurrentTimeMillisSince1970() {
            return System.currentTimeMillis();
        }
    }

    public static class Explore {

        public static HashMap optLocation(HashMap explore) {
            if (explore == null) {
                return null;
            }

            Object locationObj = explore.get("location");
            if (locationObj instanceof HashMap) {
                return (HashMap) locationObj;
            }

            Object lotEntranceObj = explore.get("entrance");
            if (lotEntranceObj instanceof HashMap) {
                return (HashMap) lotEntranceObj;
            }

            Object sectionObj = explore.get("coursesection");
            if (sectionObj instanceof HashMap) {
                HashMap sectionMap = (HashMap) sectionObj;
                Object buildingObj = sectionMap.get("building");
                if (buildingObj instanceof HashMap) {
                    return (HashMap) buildingObj;
                }
            }

            Object entrancesObj = explore.get("entrances");
            if (entrancesObj instanceof List) {
                return explore;
            }

            return null;
        }

        public static HashMap optStudentCourseBuilding(HashMap explore) {
            Object sectionObj = (explore != null) ? explore.get("coursesection") : null;
            if (sectionObj instanceof HashMap) {
                HashMap sectionMap = (HashMap) sectionObj;
                Object buildingObj = sectionMap.get("building");
                if (buildingObj instanceof HashMap) {
                    HashMap buildingMap = (HashMap) buildingObj;
                    return buildingMap;
                }
            }
            return null;
        }

        public static HashMap optStudentCourseLocation(HashMap explore) {
            return optStudentCourseBuilding(explore);
        }

        public static HashMap optBuildingDestinationLocation(HashMap buildingMap, android.location.Location origin, boolean requireAda) {
            Object entracesObj = (buildingMap != null) ? buildingMap.get("entrances") : null;
            if ((entracesObj instanceof ArrayList) && (origin != null)) {
                LatLng orgLatLng = new LatLng(origin.getLatitude(), origin.getLongitude());
                HashMap minEntrance = null, minAdaEntrance = null;
                double minDistance = -1.0, minAdaDistance = -1.0;
                ArrayList entracesList = (ArrayList) entracesObj;
                for (Object entraceObj : entracesList) {
                    if (entraceObj instanceof HashMap) {
                        HashMap entraceMap = (HashMap) entraceObj;
                        LatLng entraceLatLng = optLatLng(entraceMap);
                        if (entraceLatLng != null) {
                            double distance = Location.getDistanceBetween(orgLatLng, entraceLatLng);
                            if ((minDistance < 0.0) || (distance < minDistance)) {
                        	    minDistance = distance;
                        	    minEntrance = entraceMap;
                        	}

                            Object adaObj = entraceMap.get("adaCompliant");
                            boolean adaEntrance = (adaObj instanceof Boolean) ? (Boolean)adaObj : false;
                        	if (requireAda && (adaEntrance == true) && ((minAdaDistance < 0.0) || (distance < minAdaDistance))) {
                        	    minAdaDistance = distance;
                        	    minAdaEntrance = entraceMap;
                        	}
                        }
                    }
                }


                if (requireAda && (minAdaEntrance != null)) {
              		return minAdaEntrance;
              	}
                else if (minEntrance != null) {
              		return minEntrance;
              	}
            }
            return buildingMap;
        }

        public static Integer optLocationFloor(HashMap explore) {
            if (explore == null) {
                return null;
            }
            HashMap location = optLocation(explore);
            return optFloor(location);
        }

        public static Integer optFloor(HashMap location) {
            if (location == null) {
                return null;
            }
            Object floorObj = location.get("floor");
            if (floorObj instanceof Integer) {
                return (Integer) floorObj;
            }
            return null;
        }

        public static LatLng optLocationLatLng(HashMap explore) {
            if (explore == null) {
                return null;
            }
            ExploreType exploreType = getExploreType(explore);
            if (exploreType == ExploreType.PARKING) {
                // Json Example:
                // {"lot_id":"647b7211-9cdf-412b-a682-1fdb68897f86","lot_name":"SFC - E-14 Lot - Illinois","lot_address1":"1800 S. First Street, Champaign, IL 61820","total_spots":"1710","entrance":{"latitude":40.096691,"longitude":-88.238179},"polygon":[{"latitude":40.097938,"longitude":-88.241409},{"latitude":40.09793,"longitude":-88.238657},{"latitude":40.094742,"longitude":-88.238651},{"latitude":40.094733,"longitude":-88.240223},{"latitude":40.095148,"longitude":-88.240245},{"latitude":40.095181,"longitude":-88.24113},{"latitude":40.095636,"longitude":-88.241135},{"latitude":40.095636,"longitude":-88.241393}],"spots_sold":0,"spots_pre_sold":0}
                Object lotEntranceObj = explore.get("entrance");
                if (lotEntranceObj instanceof HashMap) {
                    HashMap lotEntranceMap = (HashMap)lotEntranceObj;
                    return optLatLng(lotEntranceMap);
                }
            } else if (exploreType == ExploreType.STUDENT_COURSE) {
                Object sectionObj = explore.get("coursesection");
                if (sectionObj instanceof HashMap) {
                    HashMap sectionMap = (HashMap)sectionObj;

                    Object buildingObj = sectionMap.get("building");
                    if (buildingObj instanceof HashMap) {
                        HashMap buildingMap = (HashMap)buildingObj;

                        return optLatLng(buildingMap);
                    }
                }
            } else if (exploreType == ExploreType.MTD_STOP) {
                Object latObj = explore.get("stop_lat");
                Object lngObj = explore.get("stop_lon");
                return ((latObj instanceof Double) && (lngObj instanceof Double) && (((double)latObj) != 0.0) && (((double)lngObj) != 0.0)) ? new LatLng((double)latObj, (double)lngObj) : null;
            } else {
                HashMap location = optLocation(explore);
                return optLatLng(location);
            }
            return null;
        }

        public static LatLng optLatLng(HashMap location) {
            if (location == null) {
                return null;
            }

            Object latObj = location.get("latitude");
            Object lngObj = location.get("longitude");
            if (!(latObj instanceof Double) || !(lngObj instanceof Double)) {
                return null;
            }

            Double lat = (Double) latObj;
            Double lng = (Double) lngObj;
            if ((lat == 0.0) && (lng == 0.0)) {
                return null;
            }

            return new LatLng(lat, lng);
        }

        public static Integer optMarkerLocationFloor(Marker marker) {
            JSONObject tag = optMarkerTagJson(marker);
            Object markerRawData = (tag != null) ? tag.opt("raw_data") : null;
            HashMap exploreMap = null;
            if (markerRawData instanceof HashMap) {
                exploreMap = (HashMap) markerRawData;
            } else if (markerRawData instanceof ArrayList) {
                ArrayList explores = (ArrayList) markerRawData;
                if (explores.size() > 0) {
                    Object exploreObj = explores.get(0);
                    if (exploreObj instanceof HashMap) {
                        exploreMap = (HashMap) exploreObj;
                    }
                }
            }
            return optLocationFloor(exploreMap);
        }

        public static boolean optSingleExploreMarker(Marker marker) {
            JSONObject markerTagJson = optMarkerTagJson(marker);
            if (markerTagJson == null) {
                return false;
            }
            return markerTagJson.optBoolean("single_explore", false);
        }

        public static MarkerOptions constructMarkerOptions(Context context, Object markerRawObject, View markerLayoutView, View markerGroupLayoutView, IconGenerator iconGenerator) {
            return constructMarkerOptions(context, markerRawObject, null, markerLayoutView, markerGroupLayoutView, iconGenerator);
        }

        public static MarkerOptions constructMarkerOptions(Context context, Object markerRawObject, LatLng location, View markerLayoutView, View markerGroupLayoutView, IconGenerator iconGenerator) {
            if (markerRawObject == null || markerLayoutView == null || markerGroupLayoutView == null || iconGenerator == null) {
                return null;
            }
            MapMarkerViewType mapMarkerViewType;
            HashMap singleExploreMap = null;
            ArrayList groupExploresJson = null;
            if (markerRawObject instanceof HashMap) {
                mapMarkerViewType = MapMarkerViewType.SINGLE;
                singleExploreMap = (HashMap) markerRawObject;
            } else if (markerRawObject instanceof ArrayList) {
                mapMarkerViewType = MapMarkerViewType.GROUP;
                groupExploresJson = (ArrayList) markerRawObject;
                Object singleObject = groupExploresJson.get(0);
                if (singleObject instanceof HashMap) {
                    singleExploreMap = (HashMap) singleObject;
                }
            } else {
                mapMarkerViewType = MapMarkerViewType.UNKNOWN;
            }
            if (mapMarkerViewType == MapMarkerViewType.UNKNOWN) {
                return null;
            }
            LatLng markerLocation = (location != null) ? location : optLocationLatLng(singleExploreMap);
            if (markerLocation == null) {
                return null;
            }
            String markerTitle = getMarkerTitle(context, mapMarkerViewType, singleExploreMap, groupExploresJson);
            MarkerOptions markerOptions = new MarkerOptions();
            markerOptions.position(markerLocation);
            markerOptions.zIndex(1);
            markerOptions.title(markerTitle);
            ExploreType exploreType = getExploreType(markerRawObject);
            Bitmap markerIcon;
            if (mapMarkerViewType == MapMarkerViewType.SINGLE) {
                String markerSnippet = getMarkerSnippet(context, singleExploreMap);
                if (markerSnippet != null && !markerSnippet.isEmpty()) {
                    markerOptions.snippet(markerSnippet);
                }
                int iconResource = getSingleExploreIconResource(exploreType);
                TextView markerTitleView = markerLayoutView.findViewById(R.id.markerTitleView);
                markerTitleView.setText(markerTitle);
                TextView markerSnippetView = markerLayoutView.findViewById(R.id.markerSnippetView);
                markerSnippetView.setText(markerSnippet);
                boolean snippetViewVisible = ((markerSnippet != null) && !markerSnippet.isEmpty());
                markerSnippetView.setVisibility(snippetViewVisible ? VISIBLE : GONE);
                ImageView iconImageView = markerLayoutView.findViewById(R.id.markerIconView);
                iconImageView.setImageResource(iconResource);
                iconGenerator.setContentView(markerLayoutView);
            } else {
                TextView markerTitleView = markerGroupLayoutView.findViewById(R.id.markerGroupTitleView);
                markerTitleView.setText(markerTitle);
                String descrLabel = getGroupExploresDescrLabel(context, markerTitle, exploreType);
                TextView markerDescrView = markerGroupLayoutView.findViewById(R.id.markerGroupDescrView);
                markerDescrView.setText(descrLabel);
                ImageView markerCircleView = markerGroupLayoutView.findViewById(R.id.markerGroupCircleView);
                Drawable circleViewBackground = markerCircleView.getBackground();
                if (circleViewBackground instanceof GradientDrawable) {
                    int exploreGroupColor = getExploreColorResource(exploreType);
                    GradientDrawable gradientDrawable = (GradientDrawable) circleViewBackground;
                    gradientDrawable.setColor(ContextCompat.getColor(context, exploreGroupColor));
                }
                iconGenerator.setContentView(markerGroupLayoutView);
            }
            markerIcon = iconGenerator.makeIcon();
            if (markerIcon != null) {
                markerOptions.icon(BitmapDescriptorFactory.fromBitmap(markerIcon));
            }
            return markerOptions;
        }

        public static boolean crossedZoomThreshold(float currentZoom, float previousZoom) {
            if (currentZoom == previousZoom) {
                return false;
            }
            float minZoom = Math.min(currentZoom, previousZoom);
            float maxZoom = Math.max(currentZoom, previousZoom);
            boolean crossedFirstThreshold = ((minZoom <= Constants.FIRST_THRESHOLD_MARKER_ZOOM) && (Constants.FIRST_THRESHOLD_MARKER_ZOOM < maxZoom));
            boolean crossedSecondThreshold = ((minZoom <= Constants.SECOND_THRESHOLD_MARKER_ZOOM) && (Constants.SECOND_THRESHOLD_MARKER_ZOOM < maxZoom));
            return crossedFirstThreshold || crossedSecondThreshold;
        }

        public static void updateCustomMarkerAppearance(Context context, Marker marker,
                                                        boolean singleExploreMarker, float currentCameraZoom, float previousCameraZoom,
                                                        View markerLayoutView, View markerGroupLayoutView, IconGenerator iconGenerator) {
            if (marker == null) {
                return;
            }
            float minCurrentZoom = Math.min(currentCameraZoom, previousCameraZoom);
            float maxCurrentZoom = Math.max(currentCameraZoom, previousCameraZoom);
            boolean changeMarkerIcon = false;
            //Check if title threshold passed
            if ((minCurrentZoom <= Constants.FIRST_THRESHOLD_MARKER_ZOOM) &&
                    (Constants.FIRST_THRESHOLD_MARKER_ZOOM < maxCurrentZoom)) {
                boolean passedFirstThreshold = (currentCameraZoom >= Constants.FIRST_THRESHOLD_MARKER_ZOOM);
                if (singleExploreMarker) {
                    showMarkerInfo(markerLayoutView, passedFirstThreshold);
                    if (passedFirstThreshold) {
                        TextView markerTitleView = markerLayoutView.findViewById(R.id.markerTitleView);
                        String markerTitle = marker.getTitle();
                        markerTitleView.setText(markerTitle);
                        TextView markerSnippetView = markerLayoutView.findViewById(R.id.markerSnippetView);
                        markerSnippetView.setVisibility(GONE);
                    }
                } else {
                    ImageView markerGroupCircleView = markerGroupLayoutView.findViewById(R.id.markerGroupCircleView);
                    int imageViewSize = context.getResources().getDimensionPixelSize(passedFirstThreshold ? R.dimen.group_marker_image_size_first : R.dimen.group_marker_image_size_zero);
                    FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(imageViewSize, imageViewSize);
                    markerGroupCircleView.setLayoutParams(layoutParams);
                    TextView markerGroupTitleView = markerGroupLayoutView.findViewById(R.id.markerGroupTitleView);
                    String markerTitle = marker.getTitle();
                    markerGroupTitleView.setText(markerTitle);
                }
                changeMarkerIcon = true;
            }
            //Check if snippet threshold passed
            if ((minCurrentZoom <= Constants.SECOND_THRESHOLD_MARKER_ZOOM) &&
                    (Constants.SECOND_THRESHOLD_MARKER_ZOOM < maxCurrentZoom)) {
                boolean passedSecondThreshold = (currentCameraZoom > Constants.SECOND_THRESHOLD_MARKER_ZOOM);
                if (singleExploreMarker) {
                    TextView markerTitleView = markerLayoutView.findViewById(R.id.markerTitleView);
                    String markerTitle = marker.getTitle();
                    markerTitleView.setText(markerTitle);
                    TextView markerSnippetView = markerLayoutView.findViewById(R.id.markerSnippetView);
                    String snippetText = marker.getSnippet();
                    boolean showSnippet = !Utils.Str.isEmpty(snippetText) && passedSecondThreshold;
                    markerSnippetView.setText(snippetText);
                    markerSnippetView.setVisibility(showSnippet ? VISIBLE : GONE);
                } else {
                    ImageView markerGroupCircleView = markerGroupLayoutView.findViewById(R.id.markerGroupCircleView);
                    int imageViewSize = context.getResources().getDimensionPixelSize(passedSecondThreshold ? R.dimen.group_marker_image_size_second : R.dimen.group_marker_image_size_first);
                    FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(imageViewSize, imageViewSize);
                    markerGroupCircleView.setLayoutParams(layoutParams);
                    TextView markerGroupTitleView = markerGroupLayoutView.findViewById(R.id.markerGroupTitleView);
                    String markerTitle = marker.getTitle();
                    markerGroupTitleView.setText(markerTitle);
                    TextView groupDescrView = markerGroupLayoutView.findViewById(R.id.markerGroupDescrView);
                    String markerDescription = Utils.Explore.optExploreMarkerDescrLabel(marker);
                    groupDescrView.setText(markerDescription);
                    int descrVisibility = passedSecondThreshold ? View.VISIBLE : View.GONE;
                    groupDescrView.setVisibility(descrVisibility);
                }
                changeMarkerIcon = true;
            }
            //Change Marker icon only if needed
            if (changeMarkerIcon) {
                iconGenerator.setContentView(singleExploreMarker ? markerLayoutView : markerGroupLayoutView);
                Bitmap icon = iconGenerator.makeIcon();
                marker.setIcon(BitmapDescriptorFactory.fromBitmap(icon));
            }
        }

        public static void showMarkerInfo(View markerLayoutView, boolean show) {
            if (markerLayoutView != null) {
                View textFrameView = markerLayoutView.findViewById(R.id.markerTextFrame);
                if (textFrameView != null) {
                    textFrameView.setVisibility(show ? VISIBLE : GONE);
                }
            }
        }

        public static JSONObject constructMarkerTagJson(Context context, String markerTitle, Object markerRawData) {
            boolean singleExploreMarker = (markerRawData instanceof HashMap);
            JSONObject markerTagJson = new JSONObject();
            try {
                markerTagJson.put("title", markerTitle);
                markerTagJson.put("raw_data", markerRawData);
                markerTagJson.put("single_explore", singleExploreMarker);
                if (!singleExploreMarker) {
                    ExploreType exploreType = getExploreType(markerRawData);
                    markerTagJson.put("description", getGroupExploresDescrLabel(context, markerTitle, exploreType));
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
            return markerTagJson;
        }

        public static Object optExploreMarkerRawData(Marker marker) {
            JSONObject markerTagJson = optMarkerTagJson(marker);
            return (markerTagJson != null) ? markerTagJson.opt("raw_data") : null;
        }

        private static String optExploreMarkerDescrLabel(Marker marker) {
            JSONObject markerTagJson = optMarkerTagJson(marker);
            return (markerTagJson != null) ? markerTagJson.optString("description", null) : null;
        }

        public static HashMap createLocationMap(LatLng latLng) {
            if (latLng == null) {
                return null;
            }
            HashMap<String, Object> location = new HashMap<>();
            location.put("latitude", latLng.latitude);
            location.put("longitude", latLng.longitude);
            return location;
        }

        public static ExploreType getExploreType(Object explore) {
            HashMap singleExplore = null;
            if (explore instanceof HashMap) {
                singleExplore = (HashMap) explore;
            } else if (explore instanceof ArrayList) {
                ArrayList explores = (ArrayList) explore;
                if (explores.size() > 0) {
                    Object firstExploreObj = explores.get(0);
                    if (firstExploreObj instanceof HashMap) {
                        singleExplore = (HashMap) firstExploreObj;
                    }
                }
            }
            if (singleExplore == null) {
                return ExploreType.UNKNOWN;
            }
            if (singleExplore.containsKey("eventId")) {
                return ExploreType.EVENT;
            } else if (singleExplore.containsKey("DiningOptionID")) {
                return ExploreType.DINING;
            } else if (singleExplore.containsKey("campus_name")) {
                return ExploreType.LAUNDRY;
            } else if (singleExplore.containsKey("lot_id")) {
                return ExploreType.PARKING;
            } else if (singleExplore.containsKey("entrances")) {
                return ExploreType.BUILDING;
            } else if (singleExplore.containsKey("coursetitle")) {
                return ExploreType.STUDENT_COURSE;
            } else if ((singleExplore.containsKey("id")) && (singleExplore.containsKey("date_time")) && (singleExplore.containsKey("type"))) {
                return ExploreType.APPOINTMENT;
            } else if (singleExplore.containsKey("stop_id")) {
                return ExploreType.MTD_STOP;
            } else if (singleExplore.containsKey("placeId")) {
                return ExploreType.POI;
            } else {
                return ExploreType.UNKNOWN;
            }
        }

        public static List<LatLng> getExplorePolygon(Object explore) {
            if (getExploreType(explore) != ExploreType.PARKING) {
                return null;
            }
            HashMap parkingLot = (HashMap) explore;
            Object polygonObject = parkingLot.get("polygon");
            if (!(polygonObject instanceof List)) {
                return null;
            }
            List<HashMap> polygonMaps = (List) polygonObject;
            if (polygonMaps.isEmpty()) {
                return null;
            }
            List<LatLng> polygonPoints = new ArrayList<>();
            for (HashMap point : polygonMaps) {
                double latitude = Utils.Map.getValueFromPath(point, "latitude", 0.0d);
                double longitude = Utils.Map.getValueFromPath(point, "longitude", 0.0d);
                LatLng latLng = new LatLng(latitude, longitude);
                polygonPoints.add(latLng);
            }
            return polygonPoints;
        }

        public static int getExploreColorResource(ExploreType exploreType) {
            int colorResource;
            switch (exploreType) {
                case EVENT:
                    colorResource = R.color.illinois_orange;
                    break;
                case DINING:
                    colorResource = R.color.mongo;
                    break;
                case MTD_STOP:
                case POI:
                    colorResource = R.color.mtdBlue;
                    break;
                default:
                    colorResource = R.color.teal;
                    break;
            }
            return colorResource;
        }

        private static String getMarkerTitle(Context context, MapMarkerViewType mapMarkerViewType, HashMap singleExploreMap, ArrayList groupExploresList) {
            if (mapMarkerViewType == MapMarkerViewType.SINGLE) {
                Object markerTitle;
                ExploreType exporeType = getExploreType(singleExploreMap);
                if (exporeType == ExploreType.PARKING) {
                    // Json Example:
                    // {"lot_id":"647b7211-9cdf-412b-a682-1fdb68897f86","lot_name":"SFC - E-14 Lot - Illinois","lot_address1":"1800 S. First Street, Champaign, IL 61820","total_spots":"1710","entrance":{"latitude":40.096691,"longitude":-88.238179},"polygon":[{"latitude":40.097938,"longitude":-88.241409},{"latitude":40.09793,"longitude":-88.238657},{"latitude":40.094742,"longitude":-88.238651},{"latitude":40.094733,"longitude":-88.240223},{"latitude":40.095148,"longitude":-88.240245},{"latitude":40.095181,"longitude":-88.24113},{"latitude":40.095636,"longitude":-88.241135},{"latitude":40.095636,"longitude":-88.241393}],"spots_sold":0,"spots_pre_sold":0}
                    markerTitle = singleExploreMap.get("lot_name");
                } else if (exporeType == ExploreType.BUILDING) {
                    markerTitle = singleExploreMap.get("name");
                } else if (exporeType == ExploreType.STUDENT_COURSE) {
                    markerTitle = singleExploreMap.get("coursetitle");
                } else if (exporeType == ExploreType.MTD_STOP) {
                    markerTitle = singleExploreMap.get("stop_name");
                } else if (exporeType == ExploreType.POI) {
                    markerTitle = singleExploreMap.get("name");
                    if (markerTitle == null) {
                        markerTitle = context.getString(R.string.location);
                    }
                } else {
                    markerTitle = singleExploreMap.get("title");
                }
                return (markerTitle instanceof String) ? ((String)markerTitle) : null;
            } else {
                return String.valueOf(groupExploresList.size());
            }
        }

        private static String getMarkerSnippet(Context context, HashMap exploreMap) {
            if (exploreMap == null) {
                return null;
            }

            ExploreType exporeType = getExploreType(exploreMap);
            if (exporeType == ExploreType.EVENT) {
                String startDateToString = (String) exploreMap.get("startDateLocal");
                if (startDateToString != null && !startDateToString.isEmpty()) {
                    Date eventStartDate = DateTime.getDateTime(startDateToString);
                    return DateTime.formatEventTime(context, eventStartDate);
                }
            }
            else if (exporeType == ExploreType.LAUNDRY) {
                return (String) exploreMap.get("status");
            }
            else if (exporeType == ExploreType.BUILDING) {
                return (String) exploreMap.get("address1");
            }
            else if (exporeType == ExploreType.MTD_STOP) {
                return (String) exploreMap.get("code");
            }
            else if (exporeType == ExploreType.POI) {
                HashMap locationMap = optLocation(exploreMap); 
                if (locationMap != null) {
                    double latitude = Utils.Map.getValueFromPath(locationMap, "latitude", 0.0d);
                    double longitude = Utils.Map.getValueFromPath(locationMap, "longitude", 0.0d);
                    return ((latitude != 0.0d) && (longitude != 0.0d)) ? String.format(Locale.getDefault(), "%.6f, %.6f", latitude, longitude) : null;
                }
            }
            else if (exporeType == ExploreType.STUDENT_COURSE) {
                String result = "";

                HashMap sectionMap = Utils.Map.getMapValueForKey(exploreMap, "coursesection");

                String buildingName = Utils.Map.getStringValueForKey(sectionMap, "buildingname");
                if ((buildingName != null) && (0 < buildingName.length())) {
                    if (0 < result.length()) {
                        result += ", ";
                    }
                    result += buildingName;
                }

                String room = Utils.Map.getStringValueForKey(sectionMap, "room");
                if ((room != null) && (0 < room.length())) {
                    if (0 < result.length()) {
                        result += ", ";
                    }
                    result += context.getString(R.string.room_label, room);
                }

                return result;
            }
            else if (exporeType == ExploreType.APPOINTMENT) {
                HashMap locationMap = Utils.Map.getMapValueForKey(exploreMap, "location");
                return Utils.Map.getStringValueForKey(locationMap, "title");
            }

            return null;
        }

        private static int getSingleExploreIconResource(ExploreType exploreType) {
            int iconResource;
            switch (exploreType) {
                case EVENT:
                    iconResource = R.drawable.marker_event;
                    break;
                case DINING:
                    iconResource = R.drawable.marker_dining;
                    break;
                case MTD_STOP:
                    iconResource = R.drawable.marker_bus;
                    break;
                case POI:
                    iconResource = R.drawable.marker_poi;
                    break;
                default:
                    iconResource = R.drawable.marker_default_teal;
                    break;
            }
            return iconResource;
        }

        private static String getGroupExploresDescrLabel(Context context, String exploresCountString, ExploreType exploreType) {
            String groupDescrLabel = "";
            if (exploresCountString != null) {
                String typeSuffix;
                switch (exploreType) {
                    case EVENT:
                        typeSuffix = context.getString(R.string.events);
                        break;
                    case DINING:
                        typeSuffix = context.getString(R.string.dinings);
                        break;
                    case LAUNDRY:
                        typeSuffix = context.getString(R.string.laundries);
                        break;
                    case PARKING:
                        typeSuffix = context.getString(R.string.parkings);
                        break;
                    case BUILDING:
                        typeSuffix = context.getString(R.string.buildings);
                        break;
                    case STUDENT_COURSE:
                        typeSuffix = context.getString(R.string.student_courses);
                        break;
                    case APPOINTMENT:
                        typeSuffix = context.getString(R.string.appointments);
                        break;
                    case MTD_STOP:
                        typeSuffix = context.getString(R.string.mtd_stops);
                        break;
                    case POI:
                        typeSuffix = context.getString(R.string.locations);
                        break;
                    default:
                        typeSuffix = context.getString(R.string.explores);
                        break;
                }
                groupDescrLabel = exploresCountString + " " + typeSuffix;
            }
            return groupDescrLabel;
        }

        private static JSONObject optMarkerTagJson(Marker marker) {
            if (marker == null) {
                return null;
            }
            Object markerTag = marker.getTag();
            if (!(markerTag instanceof JSONObject)) {
                return null;
            }
            return (JSONObject) markerTag;
        }
    }

    public static class Location {

        public static Double getDistanceBetween(LatLng firstLatLng, LatLng secondLatLng) {
            if (firstLatLng == null || secondLatLng == null) {
                return null;
            }
            android.location.Location firstLocation = new android.location.Location("firstLatLng");
            firstLocation.setLatitude(firstLatLng.latitude);
            firstLocation.setLongitude(firstLatLng.longitude);
            android.location.Location secondLocation = new android.location.Location("secondLatLng");
            secondLocation.setLatitude(secondLatLng.latitude);
            secondLocation.setLongitude(secondLatLng.longitude);
            float distance = firstLocation.distanceTo(secondLocation);
            return (double) distance;
        }
    }

    public static class Map {

        // Value for Key

        public static HashMap getMapValueForKey(HashMap map, String key) {
            Object valueObj = ((map != null) && (key != null)) ? map.get(key) : null;
            return (valueObj instanceof HashMap) ? (HashMap)valueObj : null;
        }

        public static String getStringValueForKey(HashMap map, String key) {
            Object valueObj = ((map != null) && (key != null)) ? map.get(key) : null;
            return (valueObj instanceof String) ? (String)valueObj : null;
        }

        public static int getIntValueForKey(HashMap map, String key) {
            Object valueObj = ((map != null) && (key != null)) ? map.get(key) : null;
            return (valueObj instanceof Integer) ? (Integer)valueObj : null;
        }

        public static long getLongValueForKey(HashMap map, String key) {
            Object valueObj = ((map != null) && (key != null)) ? map.get(key) : null;
            return (valueObj instanceof Long) ? (Long)valueObj : null;
        }

        public static double getDoubleValueForKey(HashMap map, String key) {
            Object valueObj = ((map != null) && (key != null)) ? map.get(key) : null;
            return (valueObj instanceof Double) ? (Double)valueObj : null;
        }

        public static boolean getBooleanValueForKey(HashMap map, String key) {
            Object valueObj = ((map != null) && (key != null)) ? map.get(key) : null;
            return (valueObj instanceof Boolean) ? (Boolean)valueObj : null;
        }

        // Value for Path

        public static String getValueFromPath(Object object, String path, String defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof String) ? (String)valueObject : defaultValue;
        }

        public static int getValueFromPath(Object object, String path, int defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof Integer) ? (Integer) valueObject : defaultValue;
        }

        public static long getValueFromPath(Object object, String path, long defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof Long) ? (Long) valueObject : defaultValue;
        }

        public static double getValueFromPath(Object object, String path, double defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof Double) ? (Double) valueObject : defaultValue;
        }

        public static boolean getValueFromPath(Object object, String path, boolean defaultValue) {
            Object valueObject = getValueFromPath(object, path);
            return (valueObject instanceof Boolean) ? (Boolean) valueObject : defaultValue;
        }

        private static Object getValueFromPath(Object object, String path) {
            if (!(object instanceof java.util.Map) || Str.isEmpty(path)) {
                return null;
            }
            java.util.Map map = (java.util.Map) object;
            int dotFirstIndex = path.indexOf(".");
            while (dotFirstIndex != -1) {
                String subPath = path.substring(0, dotFirstIndex);
                path = path.substring(dotFirstIndex + 1);
                Object innerObject = (map != null) ? map.get(subPath) : null;
                map = (innerObject instanceof HashMap) ? (HashMap) innerObject : null;
                dotFirstIndex = path.indexOf(".");
            }
            Object generalValue = (map != null) ? map.get(path) : null;
            return getPlatformValue(generalValue);
        }

        private static Object getPlatformValue(Object object) {
            if (object instanceof HashMap) {
                HashMap hashMap = (HashMap) object;
                return hashMap.get("android");
            } else {
                return object;
            }
        }
    }

    public static class Json {

        public static String getStringValueForKey(JSONObject json, String key) {
            if ((json != null) && !Str.isEmpty(key)) {
                try {
                    return json.getString(key);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
            return null;
        }

        public static Integer getIntValueForKey(JSONObject json, String key) {
            if ((json != null) && !Str.isEmpty(key)) {
                try {
                    return json.getInt(key);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
            return null;
        }

        public static Double getDoubleValueForKey(JSONObject json, String key) {
            if ((json != null) && !Str.isEmpty(key)) {
                try {
                    return json.getDouble(key);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
            return null;
        }

        public static JSONObject getJsonObjectForKey(JSONObject json, String key) {
            if ((json != null) && !Str.isEmpty(key)) {
                try {
                    return json.getJSONObject(key);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
            return null;
        }

        public static JSONArray getJsonArrayForKey(JSONObject json, String key) {
            if ((json != null) && !Str.isEmpty(key)) {
                try {
                    return json.getJSONArray(key);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
            return null;
        }

        public static JSONObject getJsonObjectForIndex(JSONArray jsonArray, int index) {
            if ((jsonArray != null) && (index >= 0)) {
                try {
                    return jsonArray.getJSONObject(index);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
            return null;
        }
    }

    public static class Str {
        public static boolean isEmpty(String value) {
            return (value == null) || value.isEmpty();
        }

        public static String nullIfEmpty(String value) {
            if (isEmpty(value)) {
                return null;
            }
            return value;
        }

        public static byte[] hexStringToByteArray(String s) {
            if(s != null) {
                int len = s.length();
                byte[] data = new byte[len / 2];
                for (int i = 0; i < len; i += 2) {
                    data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                            + Character.digit(s.charAt(i + 1), 16));
                }
                return data;
            }
            return null;
        }

        public static String byteArrayToHexString(byte[] bytes){
            if(bytes != null) {
                Formatter formatter = new Formatter();
                for (byte b : bytes) {
                    formatter.format("%02x", b);
                }
                return formatter.toString();
            }
            return null;
        }
    }

    public static class Guid {
        public static byte[] bytesFromUUID(UUID uuid) {
            ByteBuffer bb = ByteBuffer.wrap(new byte[16]);
            bb.putLong(uuid.getMostSignificantBits());
            bb.putLong(uuid.getLeastSignificantBits());

            return bb.array();
        }

        public static UUID UUIDFromBytes(byte[] bytes) {
            ByteBuffer byteBuffer = ByteBuffer.wrap(bytes);
            long high = byteBuffer.getLong();
            long low = byteBuffer.getLong();

            return new UUID(high, low);
        }
    }

    public static class Base64 {

        public static byte[] decode(String value) {
            if (value != null) {
                return android.util.Base64.decode(value, android.util.Base64.NO_WRAP);
            } else {
                return null;
            }
        }

        public static String encode(byte[] bytes) {
            if (bytes != null) {
                return android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP);
            } else {
                return null;
            }
        }
    }

    public static class AppSharedPrefs {

        public static boolean getBool(Context context, String key, boolean defaults) {
            if ((context == null) || Str.isEmpty(key)) {
                return defaults;
            }
            SharedPreferences sharedPreferences = context.getSharedPreferences(Constants.DEFAULT_SHARED_PREFS_FILE_NAME, Context.MODE_PRIVATE);
            return sharedPreferences.getBoolean(key, defaults);
        }

        public static void saveBool(Context context, String key, boolean value) {
            if ((context == null) || Str.isEmpty(key)) {
                return;
            }
            SharedPreferences sharedPreferences = context.getSharedPreferences(Constants.DEFAULT_SHARED_PREFS_FILE_NAME, Context.MODE_PRIVATE);
            SharedPreferences.Editor editor = sharedPreferences.edit();
            editor.putBoolean(key, value);
            editor.apply();
        }
    }

    public static class AppSecureSharedPrefs {

        public static String getString(Context context, String key, String defaults) {
            if ((context != null) && !Str.isEmpty(key)) {
                try {
                    SharedPreferences sharedPreferences = EncryptedSharedPreferences.create(
                        Constants.SECURE_SHARED_PREFS_FILE_NAME,
                        MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC),
                        context,
                        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                    );
                    return sharedPreferences.getString(key, defaults);
                }
                catch (Exception e) {
                    Log.e("Error", "Failed to create EncryptedSharedPreferences");
                    e.printStackTrace();
                }
            }
            return defaults;
        }

        public static void saveString(Context context, String key, String value) {
            if ((context != null) && !Str.isEmpty(key)) {
                try {
                    SharedPreferences sharedPreferences = EncryptedSharedPreferences.create(
                        Constants.SECURE_SHARED_PREFS_FILE_NAME,
                        MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC),
                        context,
                        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                    );
                    SharedPreferences.Editor editor = sharedPreferences.edit();
                    editor.putString(key, value);
                    editor.apply();
                }
                catch (Exception e) {
                    Log.e("Error", "Failed to create EncryptedSharedPreferences");
                    e.printStackTrace();
                }
            }
        }

    }

    public enum ExploreType {
        EVENT, DINING, LAUNDRY, PARKING, BUILDING, MTD_STOP, STUDENT_COURSE, APPOINTMENT, POI, UNKNOWN
    }
}
