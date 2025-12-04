// Texture Generator for Doom-like assets
export function generateTexture(type, color, width = 64, height = 64) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    // Base fill
    ctx.fillStyle = color;
    ctx.fillRect(0, 0, width, height);

    // Noise/Grime
    for (let i = 0; i < 200; i++) {
        ctx.fillStyle = `rgba(0, 0, 0, ${Math.random() * 0.2})`;
        ctx.fillRect(Math.random() * width, Math.random() * height, 2, 2);
    }

    if (type === 'wall') {
        // Bricks
        ctx.strokeStyle = 'rgba(0,0,0,0.5)';
        ctx.lineWidth = 2;
        ctx.beginPath();
        for (let y = 0; y < height; y += 16) {
            ctx.moveTo(0, y);
            ctx.lineTo(width, y);
            for (let x = (y % 32 === 0 ? 0 : 8); x < width; x += 16) {
                ctx.moveTo(x, y);
                ctx.lineTo(x, y + 16);
            }
        }
        ctx.stroke();
    } else if (type === 'floor') {
        // Tiles
        ctx.strokeStyle = 'rgba(0,0,0,0.3)';
        ctx.lineWidth = 2;
        ctx.strokeRect(0, 0, width, height);
    }

    return canvas.toDataURL();
}

export function generateSprite(type) {
    const canvas = document.createElement('canvas');
    canvas.width = 64;
    canvas.height = 64;
    const ctx = canvas.getContext('2d');

    if (type === 'imp') {
        // Brown monster
        ctx.fillStyle = '#8B4513';
        ctx.beginPath();
        ctx.arc(32, 20, 10, 0, Math.PI * 2); // Head
        ctx.fill();
        ctx.fillRect(22, 30, 20, 30); // Body
        // Eyes
        ctx.fillStyle = 'red';
        ctx.fillRect(28, 18, 2, 2);
        ctx.fillRect(34, 18, 2, 2);
        // Spikes
        ctx.fillStyle = '#eee';
        ctx.beginPath();
        ctx.moveTo(20, 30); ctx.lineTo(10, 25); ctx.lineTo(20, 35);
        ctx.fill();
        ctx.beginPath();
        ctx.moveTo(44, 30); ctx.lineTo(54, 25); ctx.lineTo(44, 35);
        ctx.fill();
    } else if (type === 'imp_attack') {
        // Attack pose
        ctx.fillStyle = '#8B4513';
        ctx.beginPath();
        ctx.arc(32, 20, 10, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillRect(22, 30, 20, 30);
        // Fireball hand
        ctx.fillStyle = 'orange';
        ctx.beginPath();
        ctx.arc(50, 30, 8, 0, Math.PI * 2);
        ctx.fill();
    } else if (type === 'imp_dead') {
        // Dead pile
        ctx.fillStyle = '#8B4513';
        ctx.fillRect(10, 50, 44, 10);
        ctx.fillStyle = 'red';
        ctx.fillRect(20, 52, 20, 5);
    } else if (type === 'pistol') {
        // Hand holding gun
        ctx.fillStyle = '#fec'; // Skin
        ctx.fillRect(20, 40, 24, 24);
        ctx.fillStyle = '#333'; // Gun
        ctx.fillRect(28, 20, 8, 30);
        ctx.fillStyle = '#111'; // Barrel hole
        ctx.fillRect(30, 20, 4, 4);
    } else if (type === 'shotgun') {
        ctx.fillStyle = '#fec';
        ctx.fillRect(10, 40, 44, 24);
        ctx.fillStyle = '#333';
        ctx.fillRect(20, 20, 24, 30);
    } else if (type === 'fireball') {
        ctx.fillStyle = 'orange';
        ctx.beginPath();
        ctx.arc(32, 32, 16, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = 'yellow';
        ctx.beginPath();
        ctx.arc(32, 32, 10, 0, Math.PI * 2);
        ctx.fill();
    }

    return canvas.toDataURL();
}
