import request from 'umi-request';

const API_BASE = '/api';

// User APIs
export async function getUsers() {
  return request(`${API_BASE}/users/`, {
    method: 'GET',
  });
}

export async function getUser(id: number) {
  return request(`${API_BASE}/users/${id}`, {
    method: 'GET',
  });
}

export async function createUser(data: { username: string; email: string }) {
  return request(`${API_BASE}/users/`, {
    method: 'POST',
    data,
  });
}

export async function updateUser(id: number, data: { username?: string; email?: string }) {
  return request(`${API_BASE}/users/${id}`, {
    method: 'PUT',
    data,
  });
}

export async function deleteUser(id: number) {
  return request(`${API_BASE}/users/${id}`, {
    method: 'DELETE',
  });
}

// Auth APIs
export async function login(data: { username: string; password: string }) {
  return request(`${API_BASE}/auth/login`, {
    method: 'POST',
    data,
  });
}

export async function logout() {
  return request(`${API_BASE}/auth/logout`, {
    method: 'POST',
  });
}

export async function getCurrentUser() {
  return request(`${API_BASE}/auth/me`, {
    method: 'GET',
  });
}
