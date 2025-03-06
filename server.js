const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');  
const cors = require('cors');
const app = express();

app.use(express.json());  // Middleware to parse JSON request body
app.use(cors());

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'Gymboost123',
    database: 'GymBoost'
});

// Test MySQL connection
db.connect(err => {
    if (err) {
        console.error('Error connecting to MySQL: ', err);
        return;
    }
    console.log('Connected to MySQL');
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
    const passwordRegex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$/; // Password must have at least one letter, one number, and be at least 6 characters
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
    // Check if the user exists in the database
    const query = 'SELECT * FROM user WHERE BINARY username = ?';
    db.query(query, [username], (err, result) => {
        if (err) {
            return res.status(500).json({ message: 'Error checking username', error: err });
        }

        console.log('User query result:', result);

        // If the user is not found
        if (result.length === 0) {
            return res.status(400).json({ message: 'Invalid username or password' });
        }

        // Compare the hashed password with the one stored in the database
        bcrypt.compare(password, result[0].passwordHash, (err, isMatch) => {
            if (err) {
                return res.status(500).json({ message: 'Error comparing passwords', error: err });
            }

            // If passwords do not match
            if (!isMatch) {
                return res.status(400).json({ message: 'Invalid username or password' });
            }
            // If it's the first login, send a response and then update the first_login flag
            if (result[0].first_login === 1) {
                res.status(200).json({ message: 'Login successful', userId: result[0].userID, firstLogin: 1 });

                // After the response, update first_login to 0
                const updateQuery = 'UPDATE user SET first_login = 0 WHERE username = ?';
                db.query(updateQuery, [username], (err) => {
                    if (err) {
                        console.error('Error updating first login status', err);
                    }
                });
            } else {
                res.status(200).json({ message: 'Login successful', userId: result[0].userID, firstLogin: 0 });
            }
        });
    });
});



// Start server
const port = 3000;
app.listen(port, () => {
    console.log("Server is running on port " + port);
});
