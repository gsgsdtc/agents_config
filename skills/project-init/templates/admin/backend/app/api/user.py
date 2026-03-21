from flask_restx import Namespace, Resource, fields
from flask import request
from app import db
from app.models.user import User

user_ns = Namespace('users', description='User management operations')

# Request/Response models for Swagger
user_model = user_ns.model('User', {
    'id': fields.Integer(readonly=True, description='User ID'),
    'username': fields.String(required=True, description='Username'),
    'email': fields.String(required=True, description='Email address'),
    'is_active': fields.Boolean(description='Is user active'),
    'created_at': fields.DateTime(readonly=True, description='Creation time'),
    'updated_at': fields.DateTime(readonly=True, description='Last update time'),
})

user_create_model = user_ns.model('UserCreate', {
    'username': fields.String(required=True, description='Username'),
    'email': fields.String(required=True, description='Email address'),
    'password': fields.String(required=True, description='Password'),
})

user_update_model = user_ns.model('UserUpdate', {
    'username': fields.String(description='Username'),
    'email': fields.String(description='Email address'),
    'is_active': fields.Boolean(description='Is user active'),
})

user_list_model = user_ns.model('UserList', {
    'items': fields.List(fields.Nested(user_model)),
    'total': fields.Integer(description='Total count'),
    'page': fields.Integer(description='Current page'),
    'per_page': fields.Integer(description='Items per page'),
})


@user_ns.route('/')
class UserList(Resource):
    @user_ns.doc('list_users')
    @user_ns.param('page', 'Page number', type=int, default=1)
    @user_ns.param('per_page', 'Items per page', type=int, default=10)
    @user_ns.param('search', 'Search by username or email', type=str)
    @user_ns.marshal_with(user_list_model)
    def get(self):
        """Get user list with pagination."""
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        search = request.args.get('search', '')

        query = User.query
        if search:
            query = query.filter(
                db.or_(
                    User.username.contains(search),
                    User.email.contains(search)
                )
            )

        pagination = query.order_by(User.created_at.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )

        return {
            'items': [user.to_dict() for user in pagination.items],
            'total': pagination.total,
            'page': page,
            'per_page': per_page,
        }

    @user_ns.doc('create_user')
    @user_ns.expect(user_create_model)
    @user_ns.marshal_with(user_model, code=201)
    @user_ns.response(400, 'Validation error')
    @user_ns.response(409, 'User already exists')
    def post(self):
        """Create a new user."""
        data = request.json

        # Check if user exists
        if User.query.filter_by(username=data['username']).first():
            user_ns.abort(409, 'Username already exists')
        if User.query.filter_by(email=data['email']).first():
            user_ns.abort(409, 'Email already exists')

        user = User(
            username=data['username'],
            email=data['email']
        )
        user.set_password(data['password'])

        db.session.add(user)
        db.session.commit()

        return user.to_dict(), 201


@user_ns.route('/<int:user_id>')
@user_ns.param('user_id', 'User ID')
class UserDetail(Resource):
    @user_ns.doc('get_user')
    @user_ns.marshal_with(user_model)
    @user_ns.response(404, 'User not found')
    def get(self, user_id):
        """Get user by ID."""
        user = User.query.get_or_404(user_id)
        return user.to_dict()

    @user_ns.doc('update_user')
    @user_ns.expect(user_update_model)
    @user_ns.marshal_with(user_model)
    @user_ns.response(404, 'User not found')
    @user_ns.response(409, 'Username or email already exists')
    def put(self, user_id):
        """Update user."""
        user = User.query.get_or_404(user_id)
        data = request.json

        if 'username' in data and data['username'] != user.username:
            if User.query.filter_by(username=data['username']).first():
                user_ns.abort(409, 'Username already exists')
            user.username = data['username']

        if 'email' in data and data['email'] != user.email:
            if User.query.filter_by(email=data['email']).first():
                user_ns.abort(409, 'Email already exists')
            user.email = data['email']

        if 'is_active' in data:
            user.is_active = data['is_active']

        db.session.commit()
        return user.to_dict()

    @user_ns.doc('delete_user')
    @user_ns.response(204, 'User deleted')
    @user_ns.response(404, 'User not found')
    def delete(self, user_id):
        """Delete user."""
        user = User.query.get_or_404(user_id)
        db.session.delete(user)
        db.session.commit()
        return '', 204
