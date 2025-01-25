import { useNavigate } from '@solidjs/router';
import { onMount, onCleanup } from 'solid-js';
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';

class WorldMap {
	constructor(containerId) {
		this.container = document.getElementById(containerId);
		this.rooms = new Map();
		this.currentLocation = null;

		this.setupScene();
		this.setupCamera();
		this.setupLights();
		this.setupControls();
		this.animate();
	}

	setupScene() {
		this.scene = new THREE.Scene();
		this.scene.background = new THREE.Color(0x000000);

		this.renderer = new THREE.WebGLRenderer({ antialias: true });
		this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
		this.container.appendChild(this.renderer.domElement);

		window.addEventListener('resize', () => {
			this.camera.aspect = this.container.clientWidth / this.container.clientHeight;
			this.camera.updateProjectionMatrix();
			this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
		});
	}

	setupCamera() {
		this.camera = new THREE.PerspectiveCamera(
			75,
			this.container.clientWidth / this.container.clientHeight,
			0.1,
			1000
		);
		this.camera.position.set(10, 10, 10);
		this.camera.lookAt(0, 0, 0);
	}

	setupLights() {
		const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
		this.scene.add(ambientLight);

		const pointLight = new THREE.PointLight(0xffffff, 1);
		pointLight.position.set(10, 10, 10);
		this.scene.add(pointLight);
	}

	setupControls() {
		this.controls = new OrbitControls(this.camera, this.renderer.domElement);
		this.controls.enableDamping = true;
		this.controls.dampingFactor = 0.05;
	}

	createRoomMesh(room) {
		const group = new THREE.Group();

		const geometry = new THREE.BoxGeometry(1, 1, 1);
		const material = new THREE.MeshStandardMaterial({
			color: 0xffffff,
			transparent: true,
			opacity: 0.6
		});
		const cube = new THREE.Mesh(geometry, material);
		group.add(cube);

		const canvas = document.createElement('canvas');
		const context = canvas.getContext('2d');
		canvas.width = 256;
		canvas.height = 64;
		context.fillStyle = '#ffffff';
		context.font = 'bold 24px Arial';
		context.textAlign = 'center';
		context.fillText(room.name, canvas.width / 2, canvas.height / 2);

		const texture = new THREE.CanvasTexture(canvas);
		const labelMaterial = new THREE.SpriteMaterial({ map: texture });
		const label = new THREE.Sprite(labelMaterial);
		label.position.y = 1;
		label.scale.set(2, 0.5, 1);
		group.add(label);

		group.position.set(room.x, room.y, room.z);
		return group;
	}

	createConnectionMesh(from, to) {
		const direction = new THREE.Vector3()
			.subVectors(new THREE.Vector3(to.x, to.y, to.z),
				new THREE.Vector3(from.x, from.y, from.z));
		const length = direction.length();

		const geometry = new THREE.CylinderGeometry(0.05, 0.05, length, 8);
		const material = new THREE.MeshStandardMaterial({ color: 0x808080 });
		const cylinder = new THREE.Mesh(geometry, material);

		cylinder.position.copy(direction.multiplyScalar(0.5).add(new THREE.Vector3(from.x, from.y, from.z)));

		cylinder.quaternion.setFromUnitVectors(
			new THREE.Vector3(0, 1, 0),
			direction.normalize()
		);

		return cylinder;
	}

	updateWorld(worldData) {
		while (this.scene.children.length > 0) {
			this.scene.remove(this.scene.children[0]);
		}
		this.setupLights();

		worldData.rooms.forEach(room => {
			const mesh = this.createRoomMesh(room);
			this.rooms.set(room.id, mesh);
			this.scene.add(mesh);

			if (room.id === worldData.currentLocation) {
				mesh.children[0].material.emissive = new THREE.Color(0x0000ff);
				mesh.children[0].material.emissiveIntensity = 0.5;
			}
		});

		worldData.connections.forEach(conn => {
			const mesh = this.createConnectionMesh(conn.from, conn.to);
			this.scene.add(mesh);
		});
	}

	animate() {
		requestAnimationFrame(() => this.animate());
		this.controls.update();
		this.renderer.render(this.scene, this.camera);
	}

	dispose() {
		this.renderer.dispose();
		this.controls.dispose();
	}
}

const MapPage = () => {
	const navigate = useNavigate();
	let containerRef;
	let worldMap;

	onMount(async () => {
		// Wait for container ref to be available
		if (!containerRef) return;

		// Initialize WorldMap with container element
		worldMap = new WorldMap(containerRef.id);

		try {
			const worldData = {
				rooms: [
					{ id: "room1", name: "The Ancient Oak Meadow", x: 0, y: 0, z: 0 },
					{ id: "room2", name: "The Mountain Path", x: 1, y: 0, z: 0 }
				],
				connections: [
					{ from: { x: 0, y: 0, z: 0 }, to: { x: 1, y: 0, z: 0 } }
				],
				currentLocation: "room1"
			};
			worldMap.updateWorld(worldData);
		} catch (err) {
			console.error('Failed to load world data:', err);
		}
	});

	onCleanup(() => {
		if (worldMap) {
			worldMap.dispose();
		}
	});

	return <>
		<button onClick={() => navigate('/')} class="absolute top-0 right-0 m-4 p-2 bg-gray-800 text-white rounded">Back</button>
		<div ref={containerRef} id="map-container" style={{ width: '100%', height: '100vh' }}></div>;
	</>;
};

export default MapPage;
