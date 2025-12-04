import * as THREE from 'https://unpkg.com/three@0.160.0/build/three.module.js';
import { generateTexture, generateSprite } from './textures.js';

// --- CONFIGURATION ---
const CONFIG = {
    tileSize: 5,
    wallHeight: 4,
    moveSpeed: 15.0,
    rotSpeed: 2.5,
    friction: 0.8,
    fov: 75
};

// --- GAME STATE ---
const state = {
    player: {
        x: 0,
        z: 0,
        dir: 0, // Radians
        velX: 0,
        velZ: 0,
        health: 100,
        ammo: 50,
        weapon: 'pistol',
        shooting: false
    },
    keys: {
        up: false, down: false, left: false, right: false, shoot: false
    },
    map: null,
    enemies: [],
    projectiles: [],
    lastTime: 0
};

// --- MAP DATA ---
const mapData = {
    width: 10,
    height: 10,
    layout: [
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 0, 0, 0, 0, 0, 0, 0, 3, 1,
        1, 0, 1, 1, 0, 1, 1, 0, 0, 1,
        1, 0, 1, 0, 0, 0, 1, 0, 0, 1,
        1, 0, 0, 0, 2, 0, 0, 0, 0, 1,
        1, 0, 1, 0, 0, 0, 1, 0, 0, 1,
        1, 0, 1, 1, 0, 1, 1, 0, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 0, 3, 1,
        1, 0, 3, 0, 0, 0, 0, 0, 0, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    ]
};

// --- THREE.JS SETUP ---
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x000000);
scene.fog = new THREE.Fog(0x000000, 0, 40);

const camera = new THREE.PerspectiveCamera(CONFIG.fov, window.innerWidth / window.innerHeight, 0.1, 100);
const renderer = new THREE.WebGLRenderer({ antialias: false }); // Retro feel
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.domElement.style.imageRendering = 'pixelated';
document.body.appendChild(renderer.domElement);

// --- ASSETS ---
const textures = {
    wall: new THREE.TextureLoader().load(generateTexture('wall', '#777')),
    floor: new THREE.TextureLoader().load(generateTexture('floor', '#444')),
    imp: new THREE.TextureLoader().load(generateSprite('imp')),
    imp_attack: new THREE.TextureLoader().load(generateSprite('imp_attack')),
    imp_dead: new THREE.TextureLoader().load(generateSprite('imp_dead')),
    pistol: generateSprite('pistol'),
    shotgun: generateSprite('shotgun'),
    fireball: new THREE.TextureLoader().load(generateSprite('fireball'))
};
Object.values(textures).forEach(t => { if (t instanceof THREE.Texture) t.magFilter = THREE.NearestFilter; });

// --- LEVEL GENERATION ---
function buildLevel() {
    const geoWall = new THREE.BoxGeometry(CONFIG.tileSize, CONFIG.wallHeight, CONFIG.tileSize);
    const matWall = new THREE.MeshStandardMaterial({ map: textures.wall });

    const geoFloor = new THREE.PlaneGeometry(CONFIG.tileSize * mapData.width, CONFIG.tileSize * mapData.height);
    const matFloor = new THREE.MeshStandardMaterial({ map: textures.floor });
    const floor = new THREE.Mesh(geoFloor, matFloor);
    floor.rotation.x = -Math.PI / 2;
    floor.position.set(
        (mapData.width * CONFIG.tileSize) / 2 - CONFIG.tileSize / 2,
        0,
        (mapData.height * CONFIG.tileSize) / 2 - CONFIG.tileSize / 2
    );
    scene.add(floor);

    // Ceiling
    const matCeil = new THREE.MeshBasicMaterial({ color: 0x222222 });
    const ceil = new THREE.Mesh(geoFloor, matCeil);
    ceil.rotation.x = Math.PI / 2;
    ceil.position.copy(floor.position);
    ceil.position.y = CONFIG.wallHeight;
    scene.add(ceil);

    state.map = [];

    for (let z = 0; z < mapData.height; z++) {
        state.map[z] = [];
        for (let x = 0; x < mapData.width; x++) {
            const type = mapData.layout[z * mapData.width + x];
            state.map[z][x] = type;

            const posX = x * CONFIG.tileSize;
            const posZ = z * CONFIG.tileSize;

            if (type === 1) { // Wall
                const wall = new THREE.Mesh(geoWall, matWall);
                wall.position.set(posX, CONFIG.wallHeight / 2, posZ);
                scene.add(wall);
            } else if (type === 2) { // Start
                state.player.x = posX;
                state.player.z = posZ;
                camera.position.set(posX, CONFIG.wallHeight / 2, posZ);
            } else if (type === 3) { // Enemy
                spawnEnemy(posX, posZ);
            }
        }
    }
}

// --- SPRITE SYSTEM ---
function spawnEnemy(x, z) {
    const material = new THREE.SpriteMaterial({ map: textures.imp });
    const sprite = new THREE.Sprite(material);
    sprite.position.set(x, CONFIG.wallHeight / 2 - 0.5, z);
    sprite.scale.set(3, 3, 1);
    scene.add(sprite);
    state.enemies.push({
        mesh: sprite,
        x: x, z: z,
        hp: 30,
        state: 'IDLE',
        lastAttack: 0
    });
}

function spawnProjectile(x, z, dirX, dirZ, owner) {
    const material = new THREE.SpriteMaterial({ map: textures.fireball });
    const sprite = new THREE.Sprite(material);
    sprite.position.set(x, CONFIG.wallHeight / 2, z);
    sprite.scale.set(1, 1, 1);
    scene.add(sprite);
    state.projectiles.push({
        mesh: sprite,
        x: x, z: z,
        vx: dirX * 20, vz: dirZ * 20,
        owner: owner
    });
}

// --- LIGHTING ---
const ambientLight = new THREE.AmbientLight(0xffffff, 0.8);
scene.add(ambientLight);

const playerLight = new THREE.PointLight(0xffaa00, 0.5, 15);
scene.add(playerLight);

// --- INPUT ---
document.addEventListener('keydown', e => {
    switch (e.code) {
        case 'ArrowUp': state.keys.up = true; break;
        case 'ArrowDown': state.keys.down = true; break;
        case 'ArrowLeft': state.keys.left = true; break;
        case 'ArrowRight': state.keys.right = true; break;
        case 'Space': state.keys.shoot = true; break;
        case 'Digit1': switchWeapon('pistol'); break;
        case 'Digit2': switchWeapon('shotgun'); break;
    }
});
document.addEventListener('keyup', e => {
    switch (e.code) {
        case 'ArrowUp': state.keys.up = false; break;
        case 'ArrowDown': state.keys.down = false; break;
        case 'ArrowLeft': state.keys.left = false; break;
        case 'ArrowRight': state.keys.right = false; break;
        case 'Space': state.keys.shoot = false; state.player.shooting = false; break;
    }
});

function switchWeapon(type) {
    state.player.weapon = type;
    const weaponEl = document.getElementById('weapon-img');
    if (weaponEl) weaponEl.src = textures[type];
}

// --- PHYSICS & COLLISION ---
function checkCollision(x, z) {
    // Simple grid collision
    const gridX = Math.round(x / CONFIG.tileSize);
    const gridZ = Math.round(z / CONFIG.tileSize);

    if (gridX < 0 || gridX >= mapData.width || gridZ < 0 || gridZ >= mapData.height) return true;

    return state.map[gridZ][gridX] === 1;
}

function updatePlayer(dt) {
    // Rotation
    if (state.keys.left) state.player.dir += CONFIG.rotSpeed * dt;
    if (state.keys.right) state.player.dir -= CONFIG.rotSpeed * dt;

    // Acceleration
    let acc = 0;
    if (state.keys.up) acc = CONFIG.moveSpeed;
    if (state.keys.down) acc = -CONFIG.moveSpeed;

    // state.player.velX += Math.sin(state.player.dir) * acc * dt;
    // state.player.velZ += Math.cos(state.player.dir) * acc * dt; // Corrected trig for 0 = North?
    // Actually Three.js: -Z is forward.
    // Let's stick to standard trig: 0 = +X, PI/2 = +Z?
    // Let's use camera rotation logic:
    // Camera looks down -Z by default.
    // We'll just use camera.rotation.y directly.

    camera.rotation.y = state.player.dir;
    const dirX = -Math.sin(state.player.dir);
    const dirZ = -Math.cos(state.player.dir);

    if (state.keys.up) {
        state.player.velX += dirX * CONFIG.moveSpeed * dt;
        state.player.velZ += dirZ * CONFIG.moveSpeed * dt;
    }
    if (state.keys.down) {
        state.player.velX -= dirX * CONFIG.moveSpeed * dt;
        state.player.velZ -= dirZ * CONFIG.moveSpeed * dt;
    }

    // Friction
    state.player.velX *= CONFIG.friction;
    state.player.velZ *= CONFIG.friction;

    // Collision & Move
    const nextX = state.player.x + state.player.velX * dt;
    const nextZ = state.player.z + state.player.velZ * dt;

    // Check X
    if (!checkCollision(nextX, state.player.z)) state.player.x = nextX;
    else state.player.velX = 0;

    // Check Z
    if (!checkCollision(state.player.x, nextZ)) state.player.z = nextZ;
    else state.player.velZ = 0;

    camera.position.x = state.player.x;
    camera.position.z = state.player.z;
    playerLight.position.copy(camera.position);

    // Shooting
    if (state.keys.shoot && !state.player.shooting) {
        fireWeapon();
        state.player.shooting = true;
    }
}

function fireWeapon() {
    // Simple Raycast
    const raycaster = new THREE.Raycaster();
    raycaster.setFromCamera(new THREE.Vector2(0, 0), camera);

    // Check enemies
    const intersects = raycaster.intersectObjects(state.enemies.map(e => e.mesh));

    if (intersects.length > 0) {
        const hit = intersects[0];
        const enemy = state.enemies.find(e => e.mesh === hit.object);
        if (enemy) {
            enemy.hp -= 10; // Pistol damage
            enemy.state = 'CHASE'; // Alert enemy
            if (enemy.hp <= 0) {
                killEnemy(enemy);
            }
        }
    }

    // Visual recoil
    const weaponEl = document.getElementById('weapon-container');
    if (weaponEl) {
        weaponEl.style.transform = 'translateX(-50%) translateY(20px)';
        setTimeout(() => weaponEl.style.transform = 'translateX(-50%) translateY(0)', 100);
    }
}

function killEnemy(enemy) {
    enemy.state = 'DEAD';
    enemy.mesh.material.map = textures.imp_dead;
    // Remove from active list eventually or just ignore
}

// --- GAME LOOP ---
function animate(time) {
    requestAnimationFrame(animate);
    const dt = Math.min((time - state.lastTime) / 1000, 0.1);
    state.lastTime = time;

    updatePlayer(dt);

    // Update Enemies
    state.enemies.forEach(enemy => {
        if (enemy.state === 'DEAD') return;

        const dist = new THREE.Vector3(enemy.x, 0, enemy.z).distanceTo(camera.position);

        // AI Logic
        if (enemy.state === 'IDLE') {
            if (dist < 20) enemy.state = 'CHASE';
        } else if (enemy.state === 'CHASE') {
            if (dist > 5) {
                const dx = state.player.x - enemy.x;
                const dz = state.player.z - enemy.z;
                const angle = Math.atan2(dx, dz);
                enemy.x += Math.sin(angle) * 3.0 * dt; // Enemy speed
                enemy.z += Math.cos(angle) * 3.0 * dt;
                enemy.mesh.position.set(enemy.x, CONFIG.wallHeight / 2 - 0.5, enemy.z);
                enemy.mesh.material.map = textures.imp;
            } else {
                enemy.state = 'ATTACK';
            }
        } else if (enemy.state === 'ATTACK') {
            if (time - enemy.lastAttack > 1000) {
                // Attack!
                enemy.mesh.material.map = textures.imp_attack;
                spawnProjectile(enemy.x, enemy.z,
                    Math.sin(Math.atan2(state.player.x - enemy.x, state.player.z - enemy.z)),
                    Math.cos(Math.atan2(state.player.x - enemy.x, state.player.z - enemy.z)),
                    'enemy'
                );
                enemy.lastAttack = time;
                setTimeout(() => { if (enemy.state !== 'DEAD') enemy.mesh.material.map = textures.imp; }, 500);
            }
            if (dist > 8) enemy.state = 'CHASE';
        }
    });

    // Update Projectiles
    for (let i = state.projectiles.length - 1; i >= 0; i--) {
        const p = state.projectiles[i];
        p.x += p.vx * dt;
        p.z += p.vz * dt;
        p.mesh.position.set(p.x, CONFIG.wallHeight / 2, p.z);

        // Collision with player
        if (p.owner === 'enemy') {
            const distToPlayer = new THREE.Vector3(p.x, 0, p.z).distanceTo(camera.position);
            if (distToPlayer < 1) {
                state.player.health -= 10;
                document.getElementById('health').innerText = state.player.health;
                scene.remove(p.mesh);
                state.projectiles.splice(i, 1);
                continue;
            }
        }

        // Collision with walls
        if (checkCollision(p.x, p.z)) {
            scene.remove(p.mesh);
            state.projectiles.splice(i, 1);
        }
    }

    renderer.render(scene, camera);
}

// --- INIT ---
buildLevel();
animate(0);

// --- HUD ---
const hud = document.createElement('div');
hud.style.position = 'absolute';
hud.style.bottom = '0';
hud.style.left = '0';
hud.style.width = '100%';
hud.style.height = '100px';
hud.style.backgroundColor = '#333';
hud.style.borderTop = '4px solid #555';
hud.style.display = 'flex';
hud.style.justifyContent = 'space-around';
hud.style.alignItems = 'center';
hud.style.fontFamily = 'Impact, sans-serif';
hud.style.fontSize = '30px';
hud.style.color = 'red';
hud.style.zIndex = '20';
hud.innerHTML = `
    <div>AMMO <span id="ammo">50</span></div>
    <div style="width: 80px; height: 80px; background: #555; border: 2px solid #000; display:flex; justify-content:center; align-items:center;">
        <div style="width:60px; height:60px; background:yellow; border-radius:50%;"></div>
    </div>
    <div>HEALTH <span id="health">100</span>%</div>
`;
document.body.appendChild(hud);

// Weapon Overlay
const weaponContainer = document.createElement('div');
weaponContainer.id = 'weapon-container';
weaponContainer.style.position = 'absolute';
weaponContainer.style.bottom = '100px';
weaponContainer.style.left = '50%';
weaponContainer.style.transform = 'translateX(-50%)';
weaponContainer.style.width = '200px';
weaponContainer.style.height = '200px';
weaponContainer.style.zIndex = '10';
weaponContainer.style.pointerEvents = 'none';

const weaponImg = document.createElement('img');
weaponImg.id = 'weapon-img';
weaponImg.src = textures.pistol;
weaponImg.style.width = '100%';
weaponImg.style.height = '100%';
weaponImg.style.imageRendering = 'pixelated';

weaponContainer.appendChild(weaponImg);
document.body.appendChild(weaponContainer);

// Handle Resize
window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
});
