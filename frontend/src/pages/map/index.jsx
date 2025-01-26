import { useNavigate } from '@solidjs/router';
import { onMount, onCleanup } from 'solid-js';
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
import { worldMap, setWorldMap } from '@features/map/stores/map';
import { mapActions } from '@features/map/stores/map';

class WorldMap {
	constructor(containerId) {
		this.container = document.getElementById(containerId);
		this.rooms = new Map();
		this.currentLocation = null;
		this.textures = new Set();

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
		this.camera.position.set(20, 20, 10);
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

		const geometry = new THREE.SphereGeometry(0.4, 16, 16);
		const material = new THREE.MeshPhongMaterial({
			color: 0x2194ce,
			transparent: true,
			opacity: 0.8
		});
		const sphere = new THREE.Mesh(geometry, material);
		group.add(sphere);

		const canvas = document.createElement('canvas');
		const context = canvas.getContext('2d');
		canvas.width = 256;
		canvas.height = 64;
		context.fillStyle = '#ffffff';
		context.font = 'bold 24px Arial';
		context.textAlign = 'center';
		context.fillText(room.name, canvas.width / 2, canvas.height / 2);

		const texture = new THREE.CanvasTexture(canvas);
		this.textures.add(texture);
		const labelMaterial = new THREE.SpriteMaterial({ map: texture });
		const label = new THREE.Sprite(labelMaterial);
		label.position.z = 1;
		label.scale.set(2, 0.5, 1);
		group.add(label);

		group.position.set(room.x * 2, room.y * 2, room.z * 2);
		return group;
	}

	createConnectionMesh(from, to) {
		const start = new THREE.Vector3(from.x * 2, from.y * 2, from.z * 2);
		const end = new THREE.Vector3(to.x * 2, to.y * 2, to.z * 2);
		
		const geometry = new THREE.BufferGeometry().setFromPoints([start, end]);
		const material = new THREE.LineBasicMaterial({ color: 0x666666 });
		return new THREE.Line(geometry, material);
	}

	updateWorld(worldData) {
		this.scene.traverse((object) => {
			if (object.geometry) {
				object.geometry.dispose();
			}
			if (object.material) {
				if (Array.isArray(object.material)) {
					object.material.forEach(material => {
						if (material.map) material.map.dispose();
						material.dispose();
					});
				} else {
					if (object.material.map) object.material.map.dispose();
					object.material.dispose();
				}
			}
		});

		this.textures.forEach(texture => texture.dispose());
		this.textures.clear();

		while (this.scene.children.length > 0) {
			this.scene.remove(this.scene.children[0]);
		}

		this.setupLights();

		worldData.rooms.forEach(room => {
			const mesh = this.createRoomMesh(room);
			this.rooms.set(room.id, mesh);
			this.scene.add(mesh);

			if (room.id === worldData.currentLocation) {
				const sphere = mesh.children[0];
				sphere.material.color.setHex(0xff3366);
				sphere.material.emissive.setHex(0xff3366);
				sphere.material.emissiveIntensity = 0.5;
				sphere.scale.setScalar(1.5);
				
				const pulseAnimation = () => {
					const time = Date.now() * 0.001;
					sphere.material.opacity = 0.8 + Math.sin(time * 2) * 0.2;
					requestAnimationFrame(pulseAnimation);
				};
				pulseAnimation();
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
		this.scene.traverse((object) => {
			if (object.geometry) {
				object.geometry.dispose();
			}
			if (object.material) {
				if (Array.isArray(object.material)) {
					object.material.forEach(material => {
						if (material.map) material.map.dispose();
						material.dispose();
					});
				} else {
					if (object.material.map) object.material.map.dispose();
					object.material.dispose();
				}
			}
		});

		this.textures.forEach(texture => texture.dispose());
		this.textures.clear();

		this.renderer.dispose();
		this.controls.dispose();
	}
}

const MapPage = () => {
	const navigate = useNavigate();
	let containerRef;

	onMount(async () => {
		// Wait for container ref to be available
		if (!containerRef) return;

		// Initialize WorldMap with container element
        setWorldMap(new WorldMap(containerRef.id));
        mapActions.requestAdminMap();
	});

	onCleanup(() => {
		if (worldMap()) {
			worldMap().dispose();
		}
	});

	return <>
		<button onClick={() => navigate('/')} class="absolute top-0 right-0 m-4 p-2 bg-gray-800 text-white rounded">Back</button>
		<div ref={containerRef} id="map-container" style={{ width: '100%', height: '100vh' }}></div>;
	</>;
};

export default MapPage;
