body {
    margin: 0;
    font-family: Arial, sans-serif;
    overflow: hidden;
}

.page {
    width: 100vw;
    height: 100vh;
    position: relative;
}

.full-image, .background-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.hidden {
    display: none;
}

.button-container {
    position: absolute;
    bottom: 15%;
    width: 100%;
    text-align: center;
}

button {
    padding: 15px 30px;
    margin: 10px;
    font-size: 18px;
    border: none;
    border-radius: 25px;
    background: linear-gradient(45deg, #8a2be2, #ff69b4);
    color: white;
    cursor: pointer;
    transition: 0.3s;
}

button:hover {
    transform: scale(1.1);
}