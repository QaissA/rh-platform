bool isAdmin(String role) => role == 'admin';

bool isRh(String role) => role == 'rh' || role == 'admin';

bool isManager(String role) =>
    role == 'manager' || role == 'rh' || role == 'admin';
