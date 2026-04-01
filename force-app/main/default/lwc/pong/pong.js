import { LightningElement } from 'lwc';

const PONG_BOARD_WIDTH = 720;
const PONG_BOARD_HEIGHT = 420;
const PONG_PADDLE_HEIGHT = 84;
const PONG_PADDLE_WIDTH = 14;
const PONG_PADDLE_OFFSET = 18;
const PONG_BALL_SIZE = 14;
const PONG_PLAYER_SPEED = 360;
const PONG_AI_SPEED = 300;
const PONG_BALL_START_SPEED = 260;
const PONG_BALL_SPEED_INCREMENT = 18;
const PONG_WINNING_SCORE = 7;

const CAR_BOARD_WIDTH = 420;
const CAR_BOARD_HEIGHT = 520;
const CAR_LANE_COUNT = 3;
const CAR_LANE_WIDTH = 112;
const CAR_LEFT_MARGIN = 42;
const CAR_PLAYER_WIDTH = 58;
const CAR_PLAYER_HEIGHT = 94;
const CAR_OBSTACLE_WIDTH = 56;
const CAR_OBSTACLE_HEIGHT = 92;
const BUS_OBSTACLE_WIDTH = 74;
const BUS_OBSTACLE_HEIGHT = 126;
const CAR_PLAYER_Y = CAR_BOARD_HEIGHT - 118;
const CAR_BASE_SPEED = 230;
const CAR_SPEED_STEP = 10;
const CAR_SPAWN_INTERVAL = 0.95;
const CAR_CRASH_DURATION = 550;

export default class Pong extends LightningElement {
    activeGame = 'pong';
    pressedKeys = new Set();

    leftPaddleY = (PONG_BOARD_HEIGHT - PONG_PADDLE_HEIGHT) / 2;
    rightPaddleY = (PONG_BOARD_HEIGHT - PONG_PADDLE_HEIGHT) / 2;
    ballX = (PONG_BOARD_WIDTH - PONG_BALL_SIZE) / 2;
    ballY = (PONG_BOARD_HEIGHT - PONG_BALL_SIZE) / 2;
    leftScore = 0;
    rightScore = 0;
    isPongRunning = false;
    pongStatusMessage = 'Press Start or hit Space to serve.';
    pongAnimationFrameId;
    pongPreviousFrameTime;
    ballVelocityX = 0;
    ballVelocityY = 0;

    carLane = 1;
    carScore = 0;
    bestCarScore = 0;
    isCarRunning = false;
    carStatusMessage = 'Stay on the road. Use Left/Right or A/D.';
    carAnimationFrameId;
    carPreviousFrameTime;
    carObstacles = [];
    nextCarObstacleId = 1;
    carSpawnTimer = 0;
    carSpeed = CAR_BASE_SPEED;
    carCrashActive = false;
    crashedObstacleId;
    crashTimeoutId;
    carHasCrashed = false;

    connectedCallback() {
        this.boundHandleKeyDown = this.handleKeyDown.bind(this);
        this.boundHandleKeyUp = this.handleKeyUp.bind(this);
        this.boundHandleVisibilityChange = this.handleVisibilityChange.bind(this);

        window.addEventListener('keydown', this.boundHandleKeyDown);
        window.addEventListener('keyup', this.boundHandleKeyUp);
        document.addEventListener('visibilitychange', this.boundHandleVisibilityChange);

        this.resetPongRound('left');
        this.resetCarGame();
    }

    disconnectedCallback() {
        window.removeEventListener('keydown', this.boundHandleKeyDown);
        window.removeEventListener('keyup', this.boundHandleKeyUp);
        document.removeEventListener('visibilitychange', this.boundHandleVisibilityChange);
        this.stopAllGames();
    }

    get cardTitle() {
        return this.activeGame === 'pong' ? 'Pong Arcade' : 'Road Dash';
    }

    get isPongActive() {
        return this.activeGame === 'pong';
    }

    get isCarActive() {
        return this.activeGame === 'car';
    }

    get pongButtonVariant() {
        return this.isPongActive ? 'brand' : 'neutral';
    }

    get carButtonVariant() {
        return this.isCarActive ? 'brand' : 'neutral';
    }

    get statusMessage() {
        return this.isPongActive ? this.pongStatusMessage : this.carStatusMessage;
    }

    get scoreboardLabel() {
        return this.isPongActive ? `${this.leftScore} : ${this.rightScore}` : `${this.carScore} m`;
    }

    get secondaryScoreLabel() {
        return this.isCarActive ? `Best ${this.bestCarScore} m` : 'First to 7 points wins';
    }

    get startPauseLabel() {
        return this.isPongActive
            ? this.isPongRunning
                ? 'Pause'
                : 'Start'
            : this.isCarRunning
              ? 'Pause'
              : 'Start';
    }

    get primaryInstruction() {
        return this.isPongActive ? 'Move: W/S or Up/Down' : 'Steer: Left/Right or A/D';
    }

    get secondaryInstruction() {
        return this.isPongActive ? 'Serve: Space or Start' : 'Launch: Space or Start';
    }

    get boardStyle() {
        return this.isPongActive
            ? `width:${PONG_BOARD_WIDTH}px;height:${PONG_BOARD_HEIGHT}px;`
            : `width:${CAR_BOARD_WIDTH}px;height:${CAR_BOARD_HEIGHT}px;`;
    }

    get leftPaddleStyle() {
        return this.getEntityStyle(
            PONG_PADDLE_OFFSET,
            this.leftPaddleY,
            PONG_PADDLE_WIDTH,
            PONG_PADDLE_HEIGHT
        );
    }

    get rightPaddleStyle() {
        return this.getEntityStyle(
            PONG_BOARD_WIDTH - PONG_PADDLE_OFFSET - PONG_PADDLE_WIDTH,
            this.rightPaddleY,
            PONG_PADDLE_WIDTH,
            PONG_PADDLE_HEIGHT
        );
    }

    get ballStyle() {
        return this.getEntityStyle(this.ballX, this.ballY, PONG_BALL_SIZE, PONG_BALL_SIZE);
    }

    get carPlayerStyle() {
        return this.getEntityStyle(
            this.getLaneX(this.carLane) + (CAR_LANE_WIDTH - CAR_PLAYER_WIDTH) / 2,
            CAR_PLAYER_Y,
            CAR_PLAYER_WIDTH,
            CAR_PLAYER_HEIGHT
        );
    }

    get playerCarClass() {
        return this.carCrashActive ? 'traffic player-car crash-active' : 'traffic player-car';
    }

    get showCrashFlash() {
        return this.carCrashActive;
    }

    get renderedObstacles() {
        return this.carObstacles.map((obstacle) => ({
            ...obstacle,
            className:
                obstacle.type === 'bus'
                    ? this.getTrafficClass('traffic traffic_bus', obstacle.id)
                    : this.getTrafficClass('traffic traffic_car', obstacle.id),
            style: this.getEntityStyle(
                this.getLaneX(obstacle.lane) + (CAR_LANE_WIDTH - obstacle.width) / 2,
                obstacle.y,
                obstacle.width,
                obstacle.height
            )
        }));
    }

    getTrafficClass(baseClassName, obstacleId) {
        return obstacleId === this.crashedObstacleId
            ? `${baseClassName} crash-active`
            : baseClassName;
    }

    getEntityStyle(x, y, width, height) {
        return `left:${x}px;top:${y}px;width:${width}px;height:${height}px;`;
    }

    handleGameSelect(event) {
        const { game } = event.currentTarget.dataset;
        if (!game || game === this.activeGame) {
            return;
        }

        this.stopAllGames();
        this.pressedKeys.clear();
        this.activeGame = game;
    }

    handleStartPause() {
        if (this.isPongActive) {
            this.handlePongStartPause();
            return;
        }

        this.handleCarStartPause();
    }

    handleReset() {
        if (this.isPongActive) {
            this.handlePongReset();
            return;
        }

        this.handleCarReset();
    }

    handleBoardClick() {
        if (this.isPongActive && !this.isPongRunning) {
            this.handlePongStartPause();
            return;
        }

        if (this.isCarActive && !this.isCarRunning) {
            this.handleCarStartPause();
        }
    }

    handleKeyDown(event) {
        const key = event.key.toLowerCase();

        if (key === ' ' || key === 'spacebar') {
            event.preventDefault();
            this.handleStartPause();
            return;
        }

        if (key === 'r') {
            this.handleReset();
            return;
        }

        if (this.isPongActive && (key === 'w' || key === 's' || key === 'arrowup' || key === 'arrowdown')) {
            event.preventDefault();
            this.pressedKeys.add(key);
        }

        if (this.isCarActive && (key === 'a' || key === 'd' || key === 'arrowleft' || key === 'arrowright')) {
            event.preventDefault();
            this.handleCarSteer(key);
        }
    }

    handleKeyUp(event) {
        this.pressedKeys.delete(event.key.toLowerCase());
    }

    handleVisibilityChange() {
        if (!document.hidden) {
            return;
        }

        if (this.isPongRunning) {
            this.stopPong('Game paused while the tab was in the background.');
        }

        if (this.isCarRunning) {
            this.stopCar('Drive paused while the tab was in the background.');
        }
    }

    handlePongStartPause() {
        if (this.isPongRunning) {
            this.stopPong('Game paused.');
            return;
        }

        if (this.isPongMatchOver()) {
            this.handlePongReset();
            return;
        }

        this.startPong();
    }

    handlePongReset() {
        this.leftScore = 0;
        this.rightScore = 0;
        this.leftPaddleY = (PONG_BOARD_HEIGHT - PONG_PADDLE_HEIGHT) / 2;
        this.rightPaddleY = (PONG_BOARD_HEIGHT - PONG_PADDLE_HEIGHT) / 2;
        this.stopPong();
        this.resetPongRound('left');
        this.pongStatusMessage = 'Match reset. Press Start or hit Space to serve.';
    }

    startPong() {
        if (this.isPongRunning) {
            return;
        }

        this.isPongRunning = true;
        this.pongStatusMessage = 'First to 7 wins. Use W/S or Up/Down.';
        this.pongPreviousFrameTime = undefined;
        this.pongAnimationFrameId = requestAnimationFrame((timestamp) => this.tickPong(timestamp));
    }

    stopPong(message) {
        this.isPongRunning = false;
        this.pongPreviousFrameTime = undefined;

        if (this.pongAnimationFrameId) {
            cancelAnimationFrame(this.pongAnimationFrameId);
            this.pongAnimationFrameId = undefined;
        }

        if (message) {
            this.pongStatusMessage = message;
        }
    }

    tickPong(timestamp) {
        if (!this.isPongRunning) {
            return;
        }

        if (!this.pongPreviousFrameTime) {
            this.pongPreviousFrameTime = timestamp;
        }

        const deltaSeconds = Math.min((timestamp - this.pongPreviousFrameTime) / 1000, 0.033);
        this.pongPreviousFrameTime = timestamp;

        this.updatePongPlayer(deltaSeconds);
        this.updatePongAi(deltaSeconds);
        this.updatePongBall(deltaSeconds);

        if (this.isPongRunning) {
            this.pongAnimationFrameId = requestAnimationFrame((nextTimestamp) =>
                this.tickPong(nextTimestamp)
            );
        }
    }

    updatePongPlayer(deltaSeconds) {
        let direction = 0;

        if (this.pressedKeys.has('w') || this.pressedKeys.has('arrowup')) {
            direction -= 1;
        }
        if (this.pressedKeys.has('s') || this.pressedKeys.has('arrowdown')) {
            direction += 1;
        }

        this.leftPaddleY = this.getClampedPaddlePosition(
            this.leftPaddleY + direction * PONG_PLAYER_SPEED * deltaSeconds
        );
    }

    updatePongAi(deltaSeconds) {
        const paddleCenter = this.rightPaddleY + PONG_PADDLE_HEIGHT / 2;
        const ballCenter = this.ballY + PONG_BALL_SIZE / 2;
        const difference = ballCenter - paddleCenter;

        if (Math.abs(difference) < 8) {
            return;
        }

        const direction = difference > 0 ? 1 : -1;
        this.rightPaddleY = this.getClampedPaddlePosition(
            this.rightPaddleY + direction * PONG_AI_SPEED * deltaSeconds
        );
    }

    updatePongBall(deltaSeconds) {
        this.ballX += this.ballVelocityX * deltaSeconds;
        this.ballY += this.ballVelocityY * deltaSeconds;

        if (this.ballY <= 0) {
            this.ballY = 0;
            this.ballVelocityY = Math.abs(this.ballVelocityY);
        } else if (this.ballY + PONG_BALL_SIZE >= PONG_BOARD_HEIGHT) {
            this.ballY = PONG_BOARD_HEIGHT - PONG_BALL_SIZE;
            this.ballVelocityY = -Math.abs(this.ballVelocityY);
        }

        const leftPaddleX = PONG_PADDLE_OFFSET;
        const rightPaddleX = PONG_BOARD_WIDTH - PONG_PADDLE_OFFSET - PONG_PADDLE_WIDTH;

        if (
            this.ballVelocityX < 0 &&
            this.ballX <= leftPaddleX + PONG_PADDLE_WIDTH &&
            this.ballX >= leftPaddleX &&
            this.intersectsPaddle(this.leftPaddleY)
        ) {
            this.ballX = leftPaddleX + PONG_PADDLE_WIDTH;
            this.reflectFromPaddle(this.leftPaddleY, 1);
        }

        if (
            this.ballVelocityX > 0 &&
            this.ballX + PONG_BALL_SIZE >= rightPaddleX &&
            this.ballX + PONG_BALL_SIZE <= rightPaddleX + PONG_PADDLE_WIDTH &&
            this.intersectsPaddle(this.rightPaddleY)
        ) {
            this.ballX = rightPaddleX - PONG_BALL_SIZE;
            this.reflectFromPaddle(this.rightPaddleY, -1);
        }

        if (this.ballX + PONG_BALL_SIZE < 0) {
            this.handlePongScore('right');
        } else if (this.ballX > PONG_BOARD_WIDTH) {
            this.handlePongScore('left');
        }
    }

    intersectsPaddle(paddleY) {
        return (
            this.ballY + PONG_BALL_SIZE >= paddleY &&
            this.ballY <= paddleY + PONG_PADDLE_HEIGHT
        );
    }

    reflectFromPaddle(paddleY, horizontalDirection) {
        const paddleCenter = paddleY + PONG_PADDLE_HEIGHT / 2;
        const ballCenter = this.ballY + PONG_BALL_SIZE / 2;
        const normalizedImpact = (ballCenter - paddleCenter) / (PONG_PADDLE_HEIGHT / 2);
        const nextHorizontalSpeed = Math.abs(this.ballVelocityX) + PONG_BALL_SPEED_INCREMENT;

        this.ballVelocityX = nextHorizontalSpeed * horizontalDirection;
        this.ballVelocityY = normalizedImpact * 220;
    }

    handlePongScore(side) {
        if (side === 'left') {
            this.leftScore += 1;
        } else {
            this.rightScore += 1;
        }

        if (this.isPongMatchOver()) {
            const winner = this.leftScore > this.rightScore ? 'You' : 'Computer';
            this.stopPong(`${winner} win ${this.leftScore} : ${this.rightScore}. Press Reset to play again.`);
            return;
        }

        this.stopPong();
        this.resetPongRound(side);
        this.pongStatusMessage = `${side === 'left' ? 'You scored' : 'Computer scored'}. Press Start or hit Space to serve.`;
    }

    resetPongRound(servingSide) {
        this.ballX = (PONG_BOARD_WIDTH - PONG_BALL_SIZE) / 2;
        this.ballY = (PONG_BOARD_HEIGHT - PONG_BALL_SIZE) / 2;

        const horizontalDirection = servingSide === 'left' ? 1 : -1;
        const verticalDirection = Math.random() > 0.5 ? 1 : -1;

        this.ballVelocityX = PONG_BALL_START_SPEED * horizontalDirection;
        this.ballVelocityY = verticalDirection * 110;
    }

    isPongMatchOver() {
        return this.leftScore >= PONG_WINNING_SCORE || this.rightScore >= PONG_WINNING_SCORE;
    }

    getClampedPaddlePosition(nextPosition) {
        return Math.max(0, Math.min(PONG_BOARD_HEIGHT - PONG_PADDLE_HEIGHT, nextPosition));
    }

    handleCarStartPause() {
        if (this.isCarRunning) {
            this.stopCar('Drive paused.');
            return;
        }

        if (this.carHasCrashed) {
            this.handleCarReset();
            return;
        }

        this.startCar();
    }

    handleCarReset() {
        this.stopCar();
        this.resetCarGame();
        this.carStatusMessage = 'Track reset. Use Left/Right or A/D to dodge traffic.';
    }

    startCar() {
        if (this.isCarRunning) {
            return;
        }

        this.isCarRunning = true;
        this.carStatusMessage = 'Keep moving. Traffic gets faster the longer you survive.';
        this.carPreviousFrameTime = undefined;
        this.carAnimationFrameId = requestAnimationFrame((timestamp) => this.tickCar(timestamp));
    }

    stopCar(message) {
        this.isCarRunning = false;
        this.carPreviousFrameTime = undefined;

        if (this.carAnimationFrameId) {
            cancelAnimationFrame(this.carAnimationFrameId);
            this.carAnimationFrameId = undefined;
        }

        if (message) {
            this.carStatusMessage = message;
        }
    }

    resetCarGame() {
        if (this.crashTimeoutId) {
            clearTimeout(this.crashTimeoutId);
            this.crashTimeoutId = undefined;
        }

        this.carLane = 1;
        this.carScore = 0;
        this.carObstacles = [];
        this.carSpawnTimer = 0;
        this.carSpeed = CAR_BASE_SPEED;
        this.carCrashActive = false;
        this.crashedObstacleId = undefined;
        this.carHasCrashed = false;
    }

    handleCarSteer(key) {
        if (key === 'arrowleft' || key === 'a') {
            this.carLane = Math.max(0, this.carLane - 1);
        }

        if (key === 'arrowright' || key === 'd') {
            this.carLane = Math.min(CAR_LANE_COUNT - 1, this.carLane + 1);
        }
    }

    tickCar(timestamp) {
        if (!this.isCarRunning) {
            return;
        }

        if (!this.carPreviousFrameTime) {
            this.carPreviousFrameTime = timestamp;
        }

        const deltaSeconds = Math.min((timestamp - this.carPreviousFrameTime) / 1000, 0.033);
        this.carPreviousFrameTime = timestamp;

        this.carScore += Math.max(1, Math.round(deltaSeconds * 42));
        this.bestCarScore = Math.max(this.bestCarScore, this.carScore);
        this.carSpeed = CAR_BASE_SPEED + Math.floor(this.carScore / 90) * CAR_SPEED_STEP;

        this.carSpawnTimer += deltaSeconds;
        if (this.carSpawnTimer >= CAR_SPAWN_INTERVAL) {
            this.spawnCarObstacle();
            this.carSpawnTimer = 0;
        }

        this.carObstacles = this.carObstacles
            .map((obstacle) => ({
                ...obstacle,
                y: obstacle.y + this.carSpeed * deltaSeconds
            }))
            .filter((obstacle) => obstacle.y < CAR_BOARD_HEIGHT + CAR_OBSTACLE_HEIGHT);

        const collidedObstacle = this.getCollidedObstacle();
        if (collidedObstacle) {
            this.handleCarCrash(collidedObstacle);
            return;
        }

        if (this.isCarRunning) {
            this.carAnimationFrameId = requestAnimationFrame((nextTimestamp) =>
                this.tickCar(nextTimestamp)
            );
        }
    }

    spawnCarObstacle() {
        const candidateLanes = [0, 1, 2].filter((lane) => {
            const mostRecentInLane = [...this.carObstacles]
                .reverse()
                .find((obstacle) => obstacle.lane === lane);
            return !mostRecentInLane || mostRecentInLane.y > 150;
        });

        const lanes = candidateLanes.length > 0 ? candidateLanes : [0, 1, 2];
        const lane = lanes[Math.floor(Math.random() * lanes.length)];
        const type = Math.random() < 0.28 ? 'bus' : 'car';
        const width = type === 'bus' ? BUS_OBSTACLE_WIDTH : CAR_OBSTACLE_WIDTH;
        const height = type === 'bus' ? BUS_OBSTACLE_HEIGHT : CAR_OBSTACLE_HEIGHT;

        this.carObstacles = [
            ...this.carObstacles,
            {
                id: this.nextCarObstacleId,
                lane,
                type,
                width,
                height,
                y: -height
            }
        ];
        this.nextCarObstacleId += 1;
    }

    getCollidedObstacle() {
        const playerX = this.getLaneX(this.carLane) + (CAR_LANE_WIDTH - CAR_PLAYER_WIDTH) / 2;
        const playerY = CAR_PLAYER_Y;

        return this.carObstacles.find((obstacle) => {
            const obstacleX =
                this.getLaneX(obstacle.lane) + (CAR_LANE_WIDTH - obstacle.width) / 2;
            const overlapX =
                playerX < obstacleX + obstacle.width &&
                playerX + CAR_PLAYER_WIDTH > obstacleX;
            const overlapY =
                playerY < obstacle.y + obstacle.height &&
                playerY + CAR_PLAYER_HEIGHT > obstacle.y;

            return overlapX && overlapY;
        });
    }

    handleCarCrash(obstacle) {
        this.bestCarScore = Math.max(this.bestCarScore, this.carScore);
        this.carCrashActive = true;
        this.crashedObstacleId = obstacle.id;
        this.carHasCrashed = true;
        this.stopCar();

        if (this.crashTimeoutId) {
            clearTimeout(this.crashTimeoutId);
        }

        this.crashTimeoutId = setTimeout(() => {
            this.carCrashActive = false;
            this.crashedObstacleId = undefined;
            this.crashTimeoutId = undefined;
            this.carStatusMessage = `Crash at ${this.carScore} m. Press Reset to run again.`;
        }, CAR_CRASH_DURATION);
    }

    getLaneX(laneIndex) {
        return CAR_LEFT_MARGIN + laneIndex * CAR_LANE_WIDTH;
    }

    stopAllGames() {
        this.stopPong();
        this.stopCar();
        if (this.crashTimeoutId) {
            clearTimeout(this.crashTimeoutId);
            this.crashTimeoutId = undefined;
        }
    }
}