const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
const cors = require('cors');
const dotenv = require('dotenv');
const crypto = require('crypto');
const multer = require("multer");
const path = require("path");
const fs = require("fs");

// Load environment variables from .env file
dotenv.config();

const app = express();

app.use(express.json());  // Middleware to parse JSON request body
app.use(cors());
app.use("/uploads", express.static(path.join(__dirname, "uploads")));


// Multer storage config (save to 'uploads/' folder)
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, "uploads/");
    },
    filename: (req, file, cb) => {
        const uniqueName = `${Date.now()}-${file.originalname}`;
        cb(null, uniqueName);
    }
});

const uploadDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

const upload = multer({ storage });



// Use environment variables from .env file
const db = mysql.createConnection({
    host: process.env.DB_HOST,     // Using DB_HOST from .env
    user: process.env.DB_USER,     // Using DB_USER from .env
    password: process.env.DB_PASSWORD, // Using DB_PASSWORD from .env
    database: process.env.DB_NAME  // Using DB_NAME from .env
});

// Test MySQL connection
db.connect(err => {
    if (err) {
        console.error('Error connecting to MySQL: ', err);
        return;
    }
    console.log('Connected to MySQL');
});



const authenticateUser = (req, res, next) => {
    const token = req.headers.authorization;

    if (!token) {
        return res.status(401).json({ message: 'Unauthorized: No token provided' });
    }

    const sessionQuery = 'SELECT * FROM sessions WHERE token = ? AND expires_at > NOW()';
    db.query(sessionQuery, [token], (err, result) => {
        if (err) return res.status(500).json({ message: 'Error checking session', error: err });

        if (result.length === 0) {
            return res.status(401).json({ message: 'Unauthorized: Invalid or expired session' });
        }

        req.user = { id: result[0].user_id };
        next();
    });
};

app.post("/upload-avatar", authenticateUser, upload.single("avatar"), (req, res) => {
    if (!req.file) {
        console.log("No file uploaded");
        return res.status(400).json({ error: "No file uploaded" });
    }

    if (!req.user || !req.user.id) {
        console.log("Unauthorized: No user ID found");
        return res.status(401).json({ error: "Unauthorized: No user ID found" });
    }

    const avatarUrl = `http://localhost:3000/uploads/${req.file.filename}`;
    const userId = req.user.id;

    console.log(`Avatar Uploaded: ${avatarUrl}`);
    console.log(`Updating avatar for user ID: ${userId}`);

    // Save to database
    const updateQuery = "UPDATE user SET avatar_url = ? WHERE userID = ?";
    db.query(updateQuery, [avatarUrl, userId], (err, result) => {
        if (err) {
            console.error("Database Error:", err);
            return res.status(500).json({ error: "Database error", details: err });
        }

        console.log(`Avatar URL updated successfully for user ID: ${userId}`);
        console.log("DB Update Result:", result);

        res.json({ avatarUrl });
    });
});


app.get('/profile', authenticateUser, (req, res) => {
    const userQuery = 'SELECT username, avatar_url FROM user WHERE userID = ?';
    db.query(userQuery, [req.user.id], (err, result) => {
        if (err) {
            console.error("Database Error:", err);
            return res.status(500).json({ message: 'Error fetching user', error: err });
        }

        if (result.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        console.log("User profile fetched:", result[0]);

        res.json({
            username: result[0].username,
            avatar_url: result[0].avatar_url || null // Ensure null if no image
        });
    });
});

app.post("/update-dark-mode", async (req, res) => {
    const { dark_mode } = req.body;
    const authToken = req.headers.authorization;

    if (!authToken) {
        return res.status(401).json({ error: "Unauthorized" });
    }

    try {
        // Fetch user from the database using the auth token
        const [user] = await db.query("SELECT id FROM users WHERE auth_token = ?", [authToken]);

        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }

        // Update the dark_mode preference
        await db.query("UPDATE users SET dark_mode = ? WHERE id = ?", [dark_mode, user.id]);

        res.json({ success: true, message: "Dark mode preference updated." });
    } catch (error) {
        console.error("Database error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

app.post('/logout', authenticateUser, (req, res) => {
    const deleteSessionQuery = 'DELETE FROM sessions WHERE user_id = ?';
    db.query(deleteSessionQuery, [req.user.id], (err) => {
        if (err) return res.status(500).json({ message: 'Error logging out', error: err });

        res.status(200).json({ message: 'Logged out successfully' });
    });
});

// Route to register a new user with hashed password and email
app.post('/register', (req, res) => {
    const { username, password } = req.body;

    // Check if the username or password is empty
    if (username.length == 0 || password.length == 0) {
        return res.status(400).json({ message: 'Username and password are required.' });
    }
    
    // Validate Username (Must be at least 3 characters long)
    if (username.length < 3) {
        return res.status(400).json({ message: 'Username must be at least 3 characters long.' });
    }

    // Validate Password (Must be at least 6 characters long)
    if (password.length < 6) {
        return res.status(400).json({ message: 'Password must be at least 6 characters long.' });
    }

    
    // Validate Password (Must contain at least one letter and one number)
    const passwordRegex = /^(?=.*[A-Za-z])(?=.*\d).{6,}$/; // Password must have at least one letter, one number, and be at least 6 characters
    if (!passwordRegex.test(password)) {
        return res.status(400).json({ message: 'Password must contain at least one letter and one number.' });
    }
    
    // Check if the username already exists in the database
    const checkQuery = 'SELECT COUNT(*) AS count FROM user WHERE BINARY username = ?';
    db.query(checkQuery, [username], (err, result) => {
        if (err) {
            return res.status(500).json({ message: 'Error checking username', error: err });
        }

        // If the count is greater than 0, the username exists
        if (result[0].count > 0) {
            return res.status(400).json({ message: 'Username already exists' });
        }

        // Hash the password using bcrypt
        bcrypt.hash(password, 10, (err, hashedPassword) => {
            if (err) {
                return res.status(500).json({ message: 'Error hashing password', error: err });
            }

            // Store the username, hashed password in the database
            const query = 'INSERT INTO user (username, passwordHash) VALUES (?, ?)';
            db.query(query, [username, hashedPassword], (err, result) => {
                if (err) {
                    return res.status(500).json({ message: 'Error saving user to database', error: err });
                }
                
                res.status(201).json({ message: 'User registered successfully', userId: result.insertId });
            });
        });
    });
});
app.post('/login', (req, res) => {
    const { username, password } = req.body;
    
    const query = 'SELECT * FROM user WHERE BINARY username = ?';
    db.query(query, [username], (err, result) => {
        if (err) return res.status(500).json({ message: 'Error checking username' });

        if (result.length === 0) return res.status(400).json({ message: 'Invalid username or password' });

        const user = result[0];

        bcrypt.compare(password, user.passwordHash, (err, isMatch) => {
            if (err) return res.status(500).json({ message: 'Error comparing passwords' });

            if (!isMatch) return res.status(400).json({ message: 'Invalid username or password' });

            const sessionToken = crypto.randomBytes(64).toString('hex');
            const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

            const sessionQuery = 'INSERT INTO sessions (user_id, token, expires_at) VALUES (?, ?, ?)';
            db.query(sessionQuery, [user.userID, sessionToken, expiresAt], (err) => {
                if (err) return res.status(500).json({ message: 'Error creating session' });

             
                const updateQuery = 'UPDATE user SET first_login = 0 WHERE userID = ?';
                db.query(updateQuery, [user.userID], (err) => {
                    if (err) console.error('Error updating first login status', err);

                    res.status(200).json({
                        message: 'Login successful',
                        token: sessionToken,
                        userId: user.userID,
                        firstLogin: user.first_login
                    });
                });
            });
        });
    });
});



// Start server
const port = process.env.PORT || 3000;
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
