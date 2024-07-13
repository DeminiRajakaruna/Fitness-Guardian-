import os
import base64
from flask import Flask
from flask_socketio import SocketIO, emit
from src.diet_recommendation import DietRecommendation
from src.exersice_recommendation import ExerciseRecommendation
from src.pose_detector import PoseDetector
from src.user_authentication import UserAuthenticator

app = Flask(__name__)
socketio = SocketIO(app, max_http_buffer_size=100000000)
pose_detector = PoseDetector()
exercise_recommendation = ExerciseRecommendation()
diet_recommendation = DietRecommendation()
user_authentication = UserAuthenticator()

def decode(encoded_data):
    return base64.b64decode(encoded_data)


@socketio.on('sendVideo')
def handle_send_video(data):
    try:
        video_name = data['name']
        encoded_video = data['file']
        video_type = data['type']

        # Decode the base64 encoded video
        video_data = decode(encoded_video)

        # Save the video to a file
        file_path = os.path.join('videos', video_name)
        with open(file_path, "wb") as video_file:
            video_file.write(video_data)
        print('Video saved')

        # Load the model and process the video
        pose_detector.stop_stream()
        pose_detector.load_model(video_type)
        pose_detector.process_video(file_path, send_feedback)

    except Exception as e:
        print(f'Error handling video upload: {e}')
        emit('videoStatus', {'message': 'Error uploading video'})

@socketio.on('stopStream')
def handle_stop_stream(data):
    pose_detector.stop_stream()

def send_feedback(feedback):
    print('Sending feedback')
    emit('posefeedbackdata', feedback)

@socketio.on('sendExercise')
def handle_send_exercise(data):
    print('exercise data recieved')
    body_part = data.get("bodyPart")
    equipment = data.get("equipment")
    target = data.get("target")

    prediction = exercise_recommendation.predict_exercise(body_part, equipment, target)

    if prediction is not None:
        emit('exerciseRecommendation', {
            'status':'success',
            'name': prediction[0],
            'secondaryMuscles': prediction[1],
            'predictedLevel': prediction[2],
            'instructions': prediction[4]
        })
    else:
        emit('exerciseRecommendation', { 'status':'failed'})


@socketio.on('sendDiet')
def handle_send_diet(data):
    user_age = float(data.get('age'))
    user_weight = float(data.get('weight'))
    user_height = float(data.get('height'))
    user_gender = data.get('gender')
    user_activity_level = float(data.get('activity_level'))

    predicted_calorie = diet_recommendation.predict_calorie(user_age, user_weight, user_height, user_gender, user_activity_level)
    print("Predicted calorie:", predicted_calorie)

    recommended_ingredients = diet_recommendation.fetch_ingredients(predicted_calorie)

    predicted_calorie_str = str(predicted_calorie)
    data_as_string = ""

    for index, row in recommended_ingredients.iterrows(): # type: ignore        
        row_string = ", ".join(map(str, row))
        data_as_string += row_string + "\n"

    print(recommended_ingredients)

    emit('dietRecommendation', {
        'predicted_calorie': predicted_calorie_str,
        'recommended_ingredients': data_as_string if recommended_ingredients is not None else 'No available combination'
    })

@socketio.on('sendUser')
def handle_user_auth(data):
    user_name = data.get('username')
    user_pass = data.get('userpassword')

    if user_authentication.authenticate_user(user_name, user_pass):
        print('user active')
        emit('userAuthentication',{'status':'success'})
    else:
        print('non user active')
        emit('userAuthentication',{'status':'failed'})


@socketio.on('connect')
def handle_connect():
    print('Client connected')


@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')


@socketio.on_error_default
def error_handler(e):
    print(f"An error occurred: {e}")
    emit('error', {'message': 'An error occurred'})


if __name__ == '__main__':
    socketio.run(app, debug=True, host='0.0.0.0', port=5000)