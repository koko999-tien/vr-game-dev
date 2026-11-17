import * as THREE from 'three';
import { VRButton } from 'three/addons/webxr/VRButton.js';
import { XRControllerModelFactory } from 'three/addons/webxr/XRControllerModelFactory.js';

// 1. Scene, Camera, and WebGLRenderer Setup
const container = document.createElement('div');
document.body.appendChild(container);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x0f172a);

const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 100);
camera.position.set(0, 1.6, 3); // Standard standing eye level (1.6m)

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(window.devicePixelRatio);
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.xr.enabled = true;
container.appendChild(renderer.domElement);

// Add the standard WebXR entry button
document.body.appendChild(VRButton.createButton(renderer));

// 2. Lighting and Spatial Environment
const hemiLight = new THREE.HemisphereLight(0xffffff, 0x334155, 1.2);
hemiLight.position.set(0, 20, 0);
scene.add(hemiLight);

const dirLight = new THREE.DirectionalLight(0xffffff, 1.5);
dirLight.position.set(3, 10, 5);
dirLight.castShadow = true;
dirLight.shadow.mapSize.width = 2048;
dirLight.shadow.mapSize.height = 2048;
scene.add(dirLight);

// Floor Grid Helper for orientation
const grid = new THREE.GridHelper(20, 40, 0x38bdf8, 0x1e293b);
grid.position.y = 0;
scene.add(grid);

// Shadow-receiving Ground Plane
const floorGeo = new THREE.PlaneGeometry(20, 20);
const floorMat = new THREE.MeshStandardMaterial({ color: 0x090d16, roughness: 0.8, metalness: 0.2 });
const floor = new THREE.Mesh(floorGeo, floorMat);
floor.rotation.x = -Math.PI / 2;
floor.receiveShadow = true;
scene.add(floor);

// 3. Interactive VR 3D Objects
const interactables = [];

// Pedestal Display Table
const tableGeo = new THREE.CylinderGeometry(0.8, 0.9, 0.8, 32);
const tableMat = new THREE.MeshStandardMaterial({ color: 0x1e293b, roughness: 0.5 });
const table = new THREE.Mesh(tableGeo, tableMat);
table.position.set(0, 0.4, -1.5);
table.receiveShadow = true;
scene.add(table);

// Central Rotating Interactive Cube
const cubeGeo = new THREE.BoxGeometry(0.3, 0.3, 0.3);
const cubeMat = new THREE.MeshStandardMaterial({ color: 0x38bdf8, roughness: 0.3, metalness: 0.7 });
const cube = new THREE.Mesh(cubeGeo, cubeMat);
cube.position.set(0, 1.0, -1.5);
cube.castShadow = true;
scene.add(cube);
interactables.push(cube);

// Orbiting Floating Interactive Spheres
const sphereColors = [0xf43f5e, 0x10b981, 0xa855f7, 0xfbbf24];
for (let i = 0; i < 4; i++) {
  const angle = (i / 4) * Math.PI * 2;
  const radius = 0.6;
  const sphereGeo = new THREE.SphereGeometry(0.1, 32, 16);
  const sphereMat = new THREE.MeshStandardMaterial({ color: sphereColors[i], roughness: 0.2, metalness: 0.5 });
  const sphere = new THREE.Mesh(sphereGeo, sphereMat);
  sphere.position.set(Math.cos(angle) * radius, 1.0, -1.5 + Math.sin(angle) * radius);
  sphere.castShadow = true;
  scene.add(sphere);
  interactables.push(sphere);
}

// 4. 6DoF Controllers, Ray Pointers & Interactions
const raycaster = new THREE.Raycaster();
const tempMatrix = new THREE.Matrix4();
const controllerModelFactory = new XRControllerModelFactory();

function buildControllerRay() {
  const geometry = new THREE.BufferGeometry().setFromPoints([
    new THREE.Vector3(0, 0, 0),
    new THREE.Vector3(0, 0, -1)
  ]);
  const line = new THREE.Line(geometry, new THREE.LineBasicMaterial({ color: 0x38bdf8 }));
  line.name = 'ray';
  line.scale.z = 5; // 5-meter pointing distance
  return line;
}

function onSelectStart(event) {
  const controller = event.target;
  const intersections = getIntersections(controller);
  if (intersections.length > 0) {
    const hit = intersections[0].object;
    // Interactive feedback: mutate color and pulse size
    hit.material.color.setHex(Math.random() * 0xffffff);
    hit.scale.multiplyScalar(1.2);
    controller.userData.selected = hit;
  }
}

function onSelectEnd(event) {
  const controller = event.target;
  if (controller.userData.selected) {
    controller.userData.selected.scale.set(1, 1, 1);
    controller.userData.selected = null;
  }
}

function getIntersections(controller) {
  tempMatrix.identity().extractRotation(controller.matrixWorld);
  raycaster.ray.origin.setFromMatrixPosition(controller.matrixWorld);
  raycaster.ray.direction.set(0, 0, -1).applyMatrix4(tempMatrix);
  return raycaster.intersectObjects(interactables, false);
}

// Instantiate both VR controllers (index 0 and 1)
const controllers = [];
for (let i = 0; i < 2; i++) {
  // Ray controller (target ray pose for aiming and trigger events)
  const controller = renderer.xr.getController(i);
  controller.addEventListener('selectstart', onSelectStart);
  controller.addEventListener('selectend', onSelectEnd);
  controller.add(buildControllerRay());
  scene.add(controller);
  controllers.push(controller);

  // Grip controller (physical hardware model representation)
  const controllerGrip = renderer.xr.getControllerGrip(i);
  controllerGrip.add(controllerModelFactory.createControllerModel(controllerGrip));
  scene.add(controllerGrip);
}

// 5. Responsive Resize Handling
window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

// 6. WebXR Synchronized Animation Loop
renderer.setAnimationLoop((time, frame) => {
  // Continuous cube rotation
  cube.rotation.x += 0.01;
  cube.rotation.y += 0.015;

  // Controller ray hover highlight detection
  controllers.forEach(controller => {
    const hits = getIntersections(controller);
    const ray = controller.getObjectByName('ray');
    if (hits.length > 0) {
      if (ray) ray.material.color.setHex(0xf43f5e); // Hover active: crimson
    } else {
      if (ray) ray.material.color.setHex(0x38bdf8); // Idle: cyan
    }
  });

  renderer.render(scene, camera);
});
