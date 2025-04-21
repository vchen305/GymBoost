const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
const cors = require('cors');
const dotenv = require('dotenv');
const crypto = require('crypto');
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const axios = require('axios');
const bodyParser = require('body-parser');

// Load environment variables from .env file
dotenv.config();

const app = express();

app.use(express.json());  // Middleware to parse JSON request body
app.use(cors());
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

app.use(bodyParser.json());


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




app.get('/caloriesData', authenticateUser, (req, res) => {
    const userID = req.user.id;

    const sql = `
        SELECT 
            daily_calories, 
            calories_consumed, 
            calories_burned, 
            calories_needed,
            carbs,
            fat,
            protein
        FROM user 
        WHERE userID = ?
    `;

    db.query(sql, [userID], (err, result) => {
        if (err) return res.status(500).json({ error: 'Database error' });

        if (result.length === 0) return res.status(404).json({ error: 'User not found' });

        res.json(result[0]);
    });
});

app.get('/sync-exercises', async (req, res) => {
    const muscleGroupMap = {
        "Leg Workout": ["hamstrings", "glutes", "calves", "quadriceps"],
        "Chest Workout": ["chest"],
        "Arms Workout": ["biceps", "triceps", "forearms"],
        "Back Workout": ["lats", "lower_back", "middle_back", "traps"],
        "Shoulder Workout": ["traps"]
    };

    try {
        for (const [workoutType, muscleGroups] of Object.entries(muscleGroupMap)) {
            for (const muscle of muscleGroups) {
                const response = await axios.get(`https://api.api-ninjas.com/v1/exercises?muscle=${muscle}`, {
                    headers: { 'X-Api-Key': process.env.EXERCISE_API_KEY }
                });

                const exercises = response.data;

                exercises.forEach(exercise => {
                    const { name, difficulty } = exercise;

                    const insertQuery = `
                        INSERT IGNORE INTO exercises (name, muscle_group, difficulty)
                        VALUES (?, ?, ?)
                    `;

                    db.query(insertQuery, [name, muscle, difficulty], (err) => {
                        if (err) {
                            console.error(`Error inserting ${name}:`, err);
                        } else {
                            console.log(`Inserted: ${name} (${muscle})`);
                        }
                    });
                });
            }
        }

        res.json({ success: true, message: 'Exercises synced.' });
    } catch (error) {
        console.error("API or DB error:", error);
        res.status(500).json({ error: "Error syncing exercises", details: error.message });
    }
});


app.get('/sync-foods', async (req, res) => {
    const foodItems = [
        'apple', 'banana', 'orange', 'grapes', 'strawberries',
        'broccoli', 'carrot', 'spinach', 'lettuce', 'onion',
        'chicken breast', 'ground beef', 'salmon', 'egg', 'milk',
        'cheddar cheese', 'yogurt', 'white rice', 'brown rice', 'pasta',
        'bread', 'oatmeal', 'peanut butter', 'almonds', 'potato'
    ];

    // Nutrients to include
    const targetNutrients = ['Protein', 'Total lipid (fat)', 'Carbohydrate, by difference'];

    try {
        for (const food of foodItems) {
            const response = await axios.get('https://api.nal.usda.gov/fdc/v1/foods/search', {
                params: {
                    query: food,
                    api_key: process.env.USDA_API_KEY,
                    pageSize: 5
                }
            });

            const foods = response.data.foods;

            if (foods && foods.length > 0) {
                for (const foodData of foods) {
                    const hasBrand = foodData.brandName && foodData.brandName.trim() !== '';
                    const name = hasBrand
                        ? `${foodData.brandName} - ${foodData.description}`
                        : foodData.description;

                    // Find calorie value (energy)
                    const energyNutrient = foodData.foodNutrients.find(nutrient =>
                        nutrient.nutrientName === 'Energy' && nutrient.unitName === 'KCAL'
                    );
                    const calories = energyNutrient?.value || null;

                    if (calories !== null) {
                        const insertFoodQuery = `
                            INSERT IGNORE INTO food (name, calories)
                            VALUES (?, ?)
                        `;

                        db.query(insertFoodQuery, [name, calories], (err) => {
                            if (err) {
                                console.error(`Error inserting food: ${name}`, err);
                                return;
                            }

                            const getFoodIdQuery = `SELECT id FROM food WHERE name = ? LIMIT 1`;
                            db.query(getFoodIdQuery, [name], (err, result) => {
                                if (err || result.length === 0) {
                                    console.error(`Error retrieving food ID for ${name}`, err);
                                    return;
                                }

                                const foodId = result[0].id;

                                for (const nutrient of foodData.foodNutrients) {
                                    if (!targetNutrients.includes(nutrient.nutrientName)) continue;

                                    const insertNutrientQuery = `
                                        INSERT INTO food_nutrients (
                                            food_id, serving_size_description,
                                            amount, unit, nutrient_name,
                                            nutrient_value, calories
                                        ) VALUES (?, ?, ?, ?, ?, ?, ?)
                                    `;

                                    db.query(insertNutrientQuery, [
                                        foodId,
                                        foodData.servingSizeUnit || 'per serving',
                                        foodData.servingSize || 1,
                                        nutrient.unitName,
                                        nutrient.nutrientName,
                                        nutrient.value,
                                        calories
                                    ], (err) => {
                                        if (err) {
                                            console.error(`Error inserting nutrient for ${name}`, err);
                                        }
                                    });
                                }
                            });
                        });
                    }
                }
            }
        }

        res.json({ success: true, message: 'Food and macronutrients synced.' });
    } catch (error) {
        console.error("API or DB error:", error);
        res.status(500).json({ error: "Error syncing food data", details: error.message });
    }
});





app.get('/api/foods', (req, res) => {
    const search = req.query.search || '';
    const sortBy = ['name', 'calories'].includes(req.query.sort) ? req.query.sort : 'name';
    const order = req.query.order === 'desc' ? 'DESC' : 'ASC';

    const query = `
        SELECT f.id AS food_id, f.name, f.calories,
               fn.id AS nutrient_id, fn.serving_size_description, fn.amount, fn.unit,
               fn.nutrient_name, fn.nutrient_value, fn.calories AS nutrient_calories
        FROM food f
        LEFT JOIN food_nutrients fn ON f.id = fn.food_id
        WHERE f.name LIKE ?
        ORDER BY ${sortBy} ${order}
        LIMIT 100
    `;

    db.query(query, [`%${search}%`], (err, results) => {
        if (err) {
            console.error('DB error:', err);
            return res.status(500).json({ error: 'Database query failed' });
        }

        const foods = [];

        const foodMap = {};

        results.forEach(row => {
            if (!foodMap[row.food_id]) {
                foodMap[row.food_id] = {
                    id: row.food_id,
                    name: row.name,
                    calories: row.calories,
                    nutrients: []
                };
                foods.push(foodMap[row.food_id]);
            }

            if (row.nutrient_id) {
                foodMap[row.food_id].nutrients.push({
                    id: row.nutrient_id,
                    food_id: row.food_id,
                    serving_size_description: row.serving_size_description,
                    amount: row.amount,
                    unit: row.unit,
                    nutrient_name: row.nutrient_name,
                    nutrient_value: row.nutrient_value,
                    calories: row.nutrient_calories
                });
            }
        });

        res.json({ data: foods });
    });
});

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


function authenticateToken(req, res, next) {
  const token = req.header('Authorization');
  if (!token) return res.status(401).json({ message: 'No token provided' });


  db.query('SELECT user_id FROM sessions WHERE token = ?', [token], (err, results) => {
    if (err) return res.status(500).json({ error: 'DB error' });
    if (results.length === 0) return res.status(403).json({ message: 'Invalid token' });

    req.userId = results[0].user_id;
    next();
  });
}

app.post('/save-workout', authenticateToken, (req, res) => {
  const { name, sets, reps, day } = req.body;
  const userID = req.userId;

  if (!name || sets === undefined || reps === undefined || !day) {
    return res.status(400).json({ message: 'Missing data' });
  }

  const validDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  if (!validDays.includes(day)) {
    return res.status(400).json({ message: 'Invalid day value' });
  }

  console.log('Received data:', { name, sets, reps, day, userID });

  db.query('SELECT id FROM exercises WHERE name = ?', [name], (err, result) => {
    if (err) {
      console.error('Error fetching exercise data:', err);
      return res.status(500).json({ message: 'Failed to fetch exercise data' });
    }

    if (result.length === 0) {
      console.log('Exercise not found:', name);
      return res.status(404).json({ message: 'Exercise not found' });
    }

    const exerciseID = result[0].id;


 
    const insertQuery = `
      INSERT INTO workouts (userID, exerciseID, sets, reps, day)
      VALUES (?, ?, ?, ?, ?)
    `;

    db.query(insertQuery, [userID, exerciseID, sets, reps, day], (err, result) => {
      if (err) {
        console.error('Insert error:', err);
        return res.status(500).json({ message: 'Failed to save workout' });
      }

      console.log('Workout saved:', result);
      res.status(201).json({ message: 'Workout saved successfully' });
    });
  });
});

app.post('/update-calories', authenticateUser, (req, res) => {
    const userID = req.user.id;
    const { daily_calories, calories_needed } = req.body;

    // Validate daily_calories and calories_needed
    if (!daily_calories || isNaN(daily_calories)) {
        return res.status(400).json({ error: "Invalid daily calorie value" });
    }

    if (calories_needed && isNaN(calories_needed)) {
        return res.status(400).json({ error: "Invalid calories_needed value" });
    }

    // Update query to handle both daily_calories and calories_needed
    const updateQuery = `
        UPDATE user 
        SET daily_calories = ?, calories_needed = ? 
        WHERE userID = ?
    `;

    db.query(updateQuery, [daily_calories, calories_needed || daily_calories, userID], (err) => {
        if (err) {
            console.error("Error updating calories:", err);
            return res.status(500).json({ error: "Database error" });
        }

        res.status(200).json({ message: "Calories updated successfully" });
    });
});

app.post('/update-calories-needed', authenticateUser, (req, res) => {
    const userID = req.user.id;
    const { food_calories, protein = 0, fat = 0, carbs = 0 } = req.body;

    if (!food_calories || isNaN(food_calories)) {
        return res.status(400).json({ error: "Invalid food calories value" });
    }

    const getQuery = `SELECT calories_needed, calories_consumed FROM user WHERE userID = ?`;
    db.query(getQuery, [userID], (err, result) => {
        if (err) {
            console.error("Error fetching current calorie data:", err);
            return res.status(500).json({ error: "Database error" });
        }

        if (result.length === 0) {
            return res.status(404).json({ error: "User not found" });
        }

        let caloriesNeeded = result[0].calories_needed;
        let caloriesConsumed = result[0].calories_consumed;

        caloriesConsumed += food_calories;
        caloriesNeeded = Math.max(0, caloriesNeeded - food_calories);

        const updateQuery = `
            UPDATE user
            SET calories_needed = ?, 
                calories_consumed = ?, 
                protein = protein + ?, 
                fat = fat + ?, 
                carbs = carbs + ?
            WHERE userID = ?
        `;
        const params = [caloriesNeeded, caloriesConsumed, protein, fat, carbs, userID];

        db.query(updateQuery, params, (err) => {
            if (err) {
                console.error("Error updating user data:", err);
                return res.status(500).json({ error: "Database error" });
            }

            res.status(200).json({ message: "User data updated successfully" });
        });
    });
});






app.get('/get-workouts', authenticateToken, (req, res) => {
  const userID = req.userId;

  const query = `
    SELECT w.day, w.sets, w.reps, e.name AS exercise_name
    FROM workouts w
    JOIN exercises e ON w.exerciseID = e.id
    WHERE w.userID = ?
    ORDER BY FIELD(w.day, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')
  `;

  db.query(query, [userID], (err, results) => {
    if (err) {
      console.error('Error fetching workouts:', err);
      return res.status(500).json({ message: 'Failed to fetch workouts' });
    }

    res.json(results);
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

app.post('/update-nutrition', authenticateUser, (req, res) => {
  const { calories_consumed, carbs, fat, protein } = req.body;
  
  // Basic validation
  if (
    calories_consumed == null ||
    carbs == null ||
    fat == null ||
    protein == null
  ) {
    return res.status(400).json({ message: 'Missing nutrition fields' });
  }

  // Update the user row and recompute calories_needed = max(daily_calories - calories_consumed, 0)
  const sql = `
    UPDATE user
    SET
      calories_consumed = ?,
      carbs              = ?,
      fat                = ?,
      protein            = ?,
      calories_needed    = GREATEST(daily_calories - ?, 0)
    WHERE userID = ?
  `;
  const params = [
    calories_consumed,
    carbs,
    fat,
    protein,
    calories_consumed,
    req.user.id
  ];

  db.query(sql, params, (err, result) => {
    if (err) {
      console.error('Error updating nutrition:', err);
      return res.status(500).json({ message: 'Database error', error: err });
    }
    res.json({ success: true });
  });
});

// Start server
const port = process.env.PORT || 3000;
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
