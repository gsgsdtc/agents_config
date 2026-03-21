from flask_restx import Namespace, Resource, fields
from flask import request, session
from app.models.user import User

auth_ns = Namespace('auth', description='Authentication operations')

login_model = auth_ns.model('Login', {
    'username': fields.String(required=True, description='Username'),
    'password': fields.String(required=True, description='Password'),
})

login_response = auth_ns.model('LoginResponse', {
    'message': fields.String(description='Response message'),
    'user': fields.Nested(auth_ns.model('AuthUser', {
        'id': fields.Integer(description='User ID'),
        'username': fields.String(description='Username'),
        'email': fields.String(description='Email'),
    }))
})

message_model = auth_ns.model('Message', {
    'message': fields.String(description='Response message'),
})


@auth_ns.route('/login')
class Login(Resource):
    @auth_ns.doc('login')
    @auth_ns.expect(login_model)
    @auth_ns.marshal_with(login_response)
    @auth_ns.response(401, 'Invalid credentials')
    def post(self):
        """User login."""
        data = request.json
        user = User.query.filter_by(username=data['username']).first()

        if user is None or not user.check_password(data['password']):
            auth_ns.abort(401, 'Invalid username or password')

        if not user.is_active:
            auth_ns.abort(401, 'User account is disabled')

        session['user_id'] = user.id

        return {
            'message': 'Login successful',
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
            }
        }


@auth_ns.route('/logout')
class Logout(Resource):
    @auth_ns.doc('logout')
    @auth_ns.marshal_with(message_model)
    def post(self):
        """User logout."""
        session.pop('user_id', None)
        return {'message': 'Logout successful'}


@auth_ns.route('/me')
class CurrentUser(Resource):
    @auth_ns.doc('current_user')
    @auth_ns.response(401, 'Not authenticated')
    def get(self):
        """Get current authenticated user."""
        user_id = session.get('user_id')
        if not user_id:
            auth_ns.abort(401, 'Not authenticated')

        user = User.query.get(user_id)
        if not user:
            session.pop('user_id', None)
            auth_ns.abort(401, 'User not found')

        return {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'is_active': user.is_active,
        }
