// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

library RabbitDeadHelper2 {
    using Strings for uint256;
    function RabbitString(string memory attack, string memory defense, uint256 kills, bool revived, string memory tokenId, uint256 mintTimestamp) public view returns (string memory) {
        string memory _level = calculatePlayerLevel(mintTimestamp, kills).toString();
        string memory _revived = revivedToString(revived);
        string memory image0 = string(abi.encodePacked('3.75-265.74v-0.04 l-0.04,0.02c-3.18,1.83-6.41,3.68-9.54,5.46c-15.95,9.1-32.44,18.51-47.52,29.82l-0.01,0.01v0.01c-2.82,24.17-5.3,46-7.13,68.41 C273.55,199.16,272.69,221.72,273.03,242.34L273.03,242.34z M306.84,1310.57c6.18-1.24,21.27-4.35,28.43-6.72 c-5.29,5.29-15.72,15.72-20.94,20.94l-0.04,0.04l0.06,0.01c5.25,0.25,10.59,0.67,15.75,1.08c8.19,0.65,16.61,1.32,24.97,1.32 c2.19,0,4.38-0.05,6.56-0.15h0.01c12.01-5.85,27.39-13.96,39.79-24.96c6.15-5.46,11.24-11.35,15.11-17.48 c4.31-6.84,7.31-14.28,8.92-22.13l0.01-0.05l-0.05,0.02c-16.76,7.36-31.53,14.26-45.14,21.11 c-15.59,7.84-29.78,15.66-43.39,23.9c0.8-3.26,1.07-6.16,0.79-8.63c-0.26-2.32-1.02-4.34-2.25-6c-1.81-2.45-4.66-4.21-8.7-5.36 c-3.16-0.91-7.11-1.46-12.41-1.74h-0.02l-0.01,0.02c-2.29,6.1-6.07,19.03-7.51,24.77l-0.01,0.04L306.84,1310.57z M378.02,470.47 l0.14,0.11l0.01-0.04c3.38-9.2,7.64-18.48,11.75-27.45c6.19-13.48,12.58-27.42,16.26-41.6c1.99-7.64,3.04-14.73,3.22-21.67 c0.21-7.79-0.68-15.2-2.71-22.64l-0.01-0.04l-0.03,0.03c-3.38,3-6.73,6.05-10.05,9.13c-5.79,5.35-11.5,10.8-17.14,16.3 c-4.09,3.96-8.13,7.95-12.14,11.94c-2.11,2.1-4.22,4.2-6.32,6.3c-1.05,1.05-2.1,2.09-3.15,3.15c-1.05,1.05-2.09,2.09-3.14,3.14 c-8.29,8.29-16.87,16.87-25.38,25.13l-0.02,0.02l0.02,0.02C345.07,445,361.82,457.95,378.02,470.47z M342.14,404.5 c26.51-23.9,52.09-48.19,76.53-72.63c1.36-1.35,2.71-2.71,4.06-4.07c0-0.01,0-0.01,0.01-0.01c2.7-2.72,5.38-5.43,8.05-8.15 c0.01-0.01,0.01-0.01,0.01-0.01c3.77-3.84,7.51-7.67,11.21-11.52c10.77-11.15,21.27-22.31,31.51-33.48l0.09-0.1l-0.12,0.05 c-14.24,6.53-29.22,14.74-45.79,25.1c-13.54,8.46-27.01,17.64-40.1,26.62c-1.22,0.83-2.43,1.66-3.64,2.49 c-1.45,0.99-2.92,2-4.4,3.02c-2.46,1.69-4.95,3.39-7.42,5.07l-0.01,0.01c-5.61,7.29-10.57,16-15.17,26.64 c-4.09,9.46-7.5,19.49-10.8,29.18c-0.16,0.49-0.33,0.97-0.5,1.46c-0.3,0.9-0.62,1.81-0.93,2.72c-0.86,2.52-1.75,5.07-2.63,7.56 l-0.04,0.1L342.14,404.5z M375.24,875.74c6.44,26.87,13.09,54.66,19.4,81.99v0.02h0.02c39.74,3.75,80.9,6.8,120.7,9.75 l0.19,0.01v-0.03L493.03,821.1c0-10.39-9.53-14.04-17.94-17.27c-1.35-0.52-2.62-1-3.84-1.52c-5.14-2.05-10.33-4.14-15.52-6.22 c-1.9-0.77-3.8-1.53-5.7-2.3c-4.24-1.71-8.47-3.41-12.64-5.09c-14.93-6.02-30.11-12.14-45.31-18.18 c-3.79-1.51-7.59-3.01-11.38-4.51c-0.01,0-0.01-0.01-0.02-0.01c-2.97-1.18-5.94-2.34-8.9-3.5c-8.42-3.3-16.81-6.56-25.14-9.74 l-0.04-0.02l0.01,0.05C355.6,793.78,365.58,835.45,375.24,875.74z M347.35,309.26l0.05-0.11c7.64-18.35,14.62-36.72,20.74-54.61 c6.39-18.69,12.04-37.44,16.8-55.74l0.01-0.01l-0.01-0.01c-2.78-12.63-6.59-26.19-11.66-41.43c-4.52-13.6-9.6-27.27-14.52-40.48 c-3.28-8.81-6.66-17.93-9.85-26.93l-0.05-0.14v0.15c0,27.28-0.65,55.14-1.27,82.08c-1.04,45.03-2.11,91.59-0.24,137.13 L347.35,309.26z M347.37,741.55c42.21,8.18,84.82,16.27,126.85,24.19c6.28,1.18,12.56,2.36,18.81,3.54 c11.42,2.15,22.79,4.29,34.08,6.41c14.99,2.82,30.11,5.66,45.31,8.53c6.28,1.18,12.58,2.37,18.88,3.56 c1.83,0.35,3.66,0.69,5.49,1.04c5.22,0.99,10.46,1.97,15.69,2.97c8.89,1.68,17.79,3.37,26.69,5.07 c10.58,2.01,21.16,4.03,31.74,6.06c12.02,2.31,24.04,4.62,36.01,6.94l0.05,0.01l-0.02-0.05c-5.63-12.33-11.07-25.17-16.33-37.6 c-5.36-12.66-10.82-25.56-16.64-38.29c-4.52-9.91-9.26-19.7-14.33-29.21l-0.01-0.01l-0.03-0.02c-0.01-0.01-0.02-0.01-0.03-0.02 c-8.23-4.38-16.5-8.79-24.83-13.2c-37.93-20.12-76.72-40.37-115.5-58.84h-0.01c-34.53,1.5-68.88,5.32-102.09,9.01h-0.01 l-0.02,0.04c-22.87,32.46-46.53,66.04-69.79,99.81l-0.02,0.03L347.37,741.55z M363.9,1281.29c22.52-9.76,44.65-21.2,66.05-32.27 l0.03-0.01v-0.02c2.03-23.68,5.49-47.6,8.83-70.73c4.07-28.16,8.29-57.29,9.94-86.16v-0.01l-0.01-0.01 c-20.67-44.05-37.85-79.35-54.05-111.11l-0.04-0.07l-0.01,0.09c-8.09,63.31-14.16,127.94-20.04,190.44 c-3.39,36.03-6.89,73.3-10.74,109.83v0.04L363.9,1281.29z M573.25,834.29c3.07,1.22,6.13,2.44,9.18,3.66 c0.4,0.16,0.79,0.31,1.18,0.47c6.72,2.67,13.49,5.37,20.28,8.08c12.31,4.9,24.72,9.87,37.14,14.87 c14.99,6.04,30,12.16,44.87,18.31h0.01l0.02,0.01v-0.01l0.01-0.02c3.75-10.13,7.76-20.24,11.63-30.02 c3.88-9.78,7.89-19.9,11.64-30.03l0.01-0.03l-0.03-0.01c-35.53-6.44-71.57-13.42-106.86-20.32c-6.89-1.35-13.76-2.7-20.58-4.04 c-6.91-1.35-13.85-2.72-20.81-4.07c-1.24-0.24-2.48-0.48-3.72-0.73c-6.97-1.36-13.96-2.72-20.98-4.09 c-45.81-8.89-92.39-17.67-138.57-25.31l-0.2-0.03l0.18,0.08C455.36,787.18,515.13,811.15,573.25,834.29z M438.22,1049.38 c2.31,4.71,4.63,9.41,6.96,14.08c2.91,5.84,5.83,11.64,8.76,17.39l0.02,0.04l0.02-0.04c1.06-1.71,2.12-3.42,3.17-5.14 c0.59-0.96,1.18-1.92,1.76-2.89c0.62-1.01,1.24-2.03,1.85-3.04c0.65-1.07,1.29-2.14,1.93-3.22c0.97-1.63,1.95-3.26,2.92-4.9 c0-0.01,0-0.01,0-0.01c2.41-4.09,4.8-8.19,7.17-12.31c0.32-0.57,0.65-1.13,0.97-1.7c1.05-1.83,2.09-3.66,3.13-5.49 c0,0,0.01-0.01,0.01-0.01c1.23-2.17,2.46-4.35,3.68-6.53c0-0.01,0.01-0.01,0.01-0.01c1.22-2.17,2.42-4.35,3.63-6.52 c9.71-17.54,19.11-35.2,28.34-52.56l0.02-0.04h-0.04c-25.65-2.56-51.84-4.47-77.17-6.31c-3.26-0.24-6.55-0.48-9.86-0.72 c-4.09-0.3-8.2-0.6-12.32-0.91c-0.23-0.02-0.46-0.04-0.68-0.05c-2.8-0.21-5.61-0.43-8.42-0.65c-1.63-0.12-3.27-0.25-4.9-0.38 h-0.05l0.03,0.05C411.88,994.57,424.93,1022.28,438.22,1049.38z M416.04,368.45c0.92,5.9,1.88,12.01,2.62,18.01l0.01,0.04 l0.03-0.02c13.39-5.82,26.23-12,38.16-18.38c12.8-6.84,25-14.13,36.26-21.69c11.97-8.02,23.26-16.6,33.58-25.49 c10.88-9.38,21.02-19.4,30.13-29.78l0.07-0.08l-0.09,0.04c-30.75,10.88-61.14,24.08-90.52,36.84 c-9.71,4.22-19.6,8.51-29.57,12.75c-5.54,2.35-11.08,4.69-16.64,6.98c-2.22,0.92-4.45,1.83-6.66,2.73l-0.02,0.01v0.01v0.02 C414.16,356.44,415.11,362.54,416.04,368.45z M439.71,326.43c16.79-5.17,34.88-11.72,55.31-20.04 c18.22-7.42,36.58-15.52,54.34-23.35c2.7-1.19,5.42-2.39,8.16-3.6c4.1-1.81,8.25-3.63,12.39-5.44c4.15-1.81,8.3-3.61,12.44-5.38 l0.01-0.01l0.01-0.01c13.51-20.55,18.31-45.39,22.96-69.39c1.27-6.6,2.59-13.41,4.06-19.94l0.02-0.07l-0.06,0.04 c-11.66,9.34-24.56,17.44-37.03,25.28c-9.83,6.18-19.99,12.56-29.49,19.52c-10.66,7.79-19.35,15.49-26.56,23.52 c-8.5,8.76-17.49,17.41-26.19,25.77c-17.39,16.73-35.37,34.04-50.38,53.05l-0.05,0.07L439.71,326.43z M459.2,1091.36 c9.54,9.12,19.12,18.35,28.6,27.53c4.21,4.07,8.41,8.14,12.58,12.19c3.13,3.03,6.25,6.06,9.34,9.06 c4.13,4.01,8.28,8.04,12.45,12.08c0,0,0,0,0.01,0.01c8.33,8.07,16.73,16.2,25.19,24.33c21.14,20.33,42.6,40.7,64.22,60.44 l0.05,0.05l-0.01-0.07c-2.82-21.33-7.22-42.6-11.48-63.16c-3.69-17.82-7.5-36.24-10.29-54.69c-2.08-18.72-3.95-37.62-5.77-55.9 c-2.76-27.85-5.61-56.66-9.24-85.23l-0.01-0.02h-0.02c-1.07,0.09-2.16,0.16-3.25,0.19c-3.98,0.15-8.08-0.02-12.14-0.25 c-1-0.05-2-0.12-3-0.18c-5.85-0.35-11.89-0.71-17.66-0.3c-6.47,0.46-11.87,1.86-16.51,4.29h-0.01l-0.01,0.01 c-14.18,21.49-26.65,44.27-38.71,66.3c-7.78,14.22-15.83,28.93-24.35,43.3l-0.01,0.02L459.2,1091.36z M498.99,1312.82 c5.82,3.6,11.22,8.2,16.45,12.65c2.23,1.91,4.51,3.85,6.84,5.73c0.58,0.47,1.17,0.94,1.76,1.4c1.77,1.38,3.57,2.72,5.41,3.97 c4.13,2.81,8.12,4.94,12.11,6.46c1.32,0.51,2.65,0.95,3.98,1.32c9.43,0.54,18.88,1.02,28.36,1.46c2.95,0.13,5.9,0.27,8.85,0.4 c12.44,0.55,24.88,1.03,37.31,1.46c24.86,0.86,49.62,1.54,73.97,2.2c29.04,0.79,59.06,1.61,88.73,2.73l0.03,0.01v-30.08 l-0.02-0.01c-17.52-3.5-35.33-7.15-52.55-10.68c-34.44-7.05-70.06-14.35-105.08-20.85c-36.04-3-73.06-3-108.85-3h-0.02 l-0.01,0.01c-0.75,1.03-1.49,2.07-2.23,3.11c-0.73,1.04-1.46,2.08-2.17,3.11c-1.44,2.08-2.85,4.14-4.23,6.17 c-1.73,2.53-3.5,5.12-5.31,7.72c-0.72,1.04-1.46,2.08-2.2,3.11c-0.37,0.52-0.74,1.03-1.12,1.55l-0.02,0.02L498.99,1312.82z M505.78,846.7c0.7,4.73,1.41,9.47,2.12,14.22c0.12,0.8,0.24,1.61,0.37,2.42c0.95,6.36,1.92,12.72,2.89,19.1 c1.47,9.58,2.96,19.16,4.49,28.74c0.85,5.33,1.71,10.66,2.58,15.98c0.32,1.95,0.64,3.9,0.96,5.85c1.34,8.08,2.7,16.14,4.1,24.16 c0.65,3.7,1.3,7.4,1.96,11.09v0.02h0.02c5.16,0,10.41,0.13,15.47,0.25c5.01,0.12,10.09,0.24,15.17,0.24 c7.63,0,15.26-0.27,22.65-1.24l0.02-0.01c23.28-17.21,45.98-35.8,67.92-53.78c10.64-8.72,21.66-17.74,32.67-26.54l0.04-0.03 l-0.04-0.01c-3.71-1.55-7.42-3.09-11.13-4.63c-7.43-3.08-14.86-6.14-22.31-9.18c-7.45-3.04-14.91-6.08-22.37-9.1 c-7.43-3-14.86-5.99-22.28-8.96c-33.54-13.43-66.97-26.54-99.78-39.42l-0.08-0.04l0.01,0.09 C502.75,826.1,504.26,836.38,505.78,846.7z M593.49,1063.74c2.41,19.14,4.91,38.93,6.08,58.39l0.01,0.02v0.01l0.02-0.01 c94.36-21.04,189.92-43.74,282.33-65.7c9.98-2.37,19.96-4.74,29.96-7.11l0.05-0.01l-0.04-0.03 c-86.35-61.93-157.67-112.02-224.45-157.64l-0.02-0.01l-0.02,0.01c-18.14,15.66-37.01,30.65-55.27,45.14 c-7.48,5.94-15.08,11.98-22.68,18.1c-1.3,1.05-2.61,2.1-3.91,3.16c-2.49,2.02-4.98,4.04-7.46,6.08 c-3.78,3.1-7.54,6.21-11.27,9.34v0.01l-0.01,0.01v0.01c-0.41,13.49,0.1,28.25,1.57,45.12 C589.69,1033.65,591.62,1048.95,593.49,1063.74z M615.21,1202.73c5.37,26.14,10.92,53.16,14.39,80.05v0.02h0.01h0.02 c23.65,4.13,47.51,9.09,70.57,13.89c23.06,4.8,46.91,9.76,70.56,13.88l0.08,0.02l-0.06-0.06c-1.63-1.67-3.26-3.34-4.89-5.02 c-8.22-8.44-16.55-16.97-24.96-25.56c-1.63-1.66-3.25-3.32-4.88-4.98c-8.4-8.57-16.89-17.19-25.47-25.85 c-12.01-12.13-24.18-24.33-36.5-36.56c-3.52-3.5-7.05-6.99-10.59-10.48c-1.77-1.75-3.54-3.5-5.32-5.24 c-3.55-3.5-7.11-6.98-10.69-10.48c-3.57-3.49-7.16-6.98-10.75-10.47c-3.59-3.49-7.2-6.97-10.81-10.45 c-7.23-6.96-14.49-13.9-21.79-20.81l-0.05-0.05l0.01,0.08C607.25,1163.99,611.29,1183.68,615.21,1202.73z M749.74,1275.07 c12.05,11.87,24.5,24.14,36.76,36.25l0.02,0.03l0.02-0.04c9.2-18.4,18.59-36.92,27.98-55.34c1.97-3.86,3.94-7.72,5.91-11.56 c7.43-14.52,14.85-28.95,22.16-43.19c4.46-8.68,8.95-17.41,13.45-26.19c3-5.85,6-11.7,9.01-17.59 c16.55-32.34,33.15-65.11,49.11-97.61l0.02-0.05l-0.05,0.01c-16.08,3.4-32.2,6.89-48.33,10.44c-12.9,2.84-25.83,5.72-38.74,8.64 c-0.01,0.01-0.01,0.01-0.02,0.01c-9.69,2.19-19.38,4.39-29.07,6.62c-46.03,10.57-92,21.48-137.46,32.4 c-4.85,1.16-9.69,2.33-14.54,3.49c-1.53,0.37-3.06,0.74-4.59,1.1c-4.84,1.16-9.66,2.33-14.48,3.48 c-7.11,1.71-14.21,3.42-21.29,5.13l-0.05,0.01l0.04,0.04C652.94,1179.7,702.15,1228.18,749.74,1275.07z M699.73,772.36 c0.76,1.77,1.52,3.53,2.3,5.28c0.51,1.16,1.02,2.3,1.53,3.45c1.44,3.24,2.91,6.47,4.41,9.68c0.81,1.74,1.63,3.47,2.47,5.2 c0.83,1.73,1.67,3.45,2.52,5.17c1.7,3.43,3.43,6.84,5.22,10.22l0.01,0.01l0.01,0.01c24.47,14.43,50.87,25.87,76.4,36.93 c4.99,2.16,10.15,4.4,15.19,6.61l0.12,0.05l-0.09-0.09c-19.57-21.37-40.69-43.32-62.77-65.21 c-20.67-20.49-42.74-41.49-65.59-62.4l-0.09-0.08l0.04,0.11C687.28,742.18,693.27,757.36,699.73,772.36z M694.16,884.17 l0.01,0.01c4.86,3.34,9.72,6.71,14.57,10.1c3.23,2.25,6.47,4.52,9.7,6.79c1.61,1.14,3.23,2.27,4.84,3.41 c3.23,2.28,6.44,4.56,9.66,6.83c12.86,9.13,25.63,18.28,38.17,27.27c5.58,4.01,11.2,8.03,16.83,12.06 c14.08,10.08,28.31,20.21,42.68,30.25c4.9,3.42,9.82,6.84,14.75,10.24c0.86,0.59,1.72,1.18,2.58,1.77 c2.03,1.4,4.07,2.8,6.11,4.18c2.31,1.58,4.63,3.16,6.95,4.73c4.37,2.97,8.76,5.91,13.15,8.83c2.6,1.73,5.2,3.45,7.81,5.16 c9.16,6.03,18.37,11.95,27.64,17.76l0.07,0.04l-0.04-0.07c-10.56-24.08-22.28-48.34-33.6-71.8 c-8.81-18.24-17.92-37.1-26.45-55.81c-1.44-2.7-2.73-5.62-3.97-8.45c-1.99-4.5-4.04-9.15-6.77-13.1 c-3.07-4.43-6.68-7.45-11.04-9.25c-6.78-3.32-13.6-6.66-20.46-10.01c-3.82-1.86-7.66-3.73-11.51-5.6 c-14.54-7.06-29.23-14.11-44-21c-4.66-2.17-9.34-4.33-14.02-6.47c-0.01,0-0.01,0-0.01-0.01c-4.68-2.14-9.37-4.26-14.06-6.35 c-2.34-1.05-4.69-2.08-7.04-3.12l-0.02-0.01l-0.01,0.04c-7.38,19.92-15.01,40.52-22.51,61.54v0.01L694.16,884.17L694.16,884.17z M875.86,1158.18c24.17-6.66,46.4-13.48,66.06-20.27l0.02-0.01l-0.01-0.02c-1.2-4.8-2.41-9.63-3.63-14.49 c-0.56-2.23-1.13-4.47-1.69-6.71c-0.19-0.76-0.38-1.52-0.58-2.28c-1.04-4.12-2.09-8.26-3.16-12.4 c-3.11-12.06-6.33-24.18-9.71-36.19l-0.02-0.06l-0.03,0.05c-17.19,29.89-33.09,60.95-47.29,92.33l-0.02,0.05L875.86,1158.18z M941.13,1099.61c2.77,10.33,5.63,21.02,8.26,31.53l0.01,0.05l0.04-0.04c4.55-5.38,9.01-10.86,13.42-16.37 c5.86-7.35,11.6-14.76,17.24-22.09c1.41-1.83,2.81-3.65,4.21-5.47c4.06-5.28,8.25-10.74,12.43-16.12l0.01-0.01l-0.01-0.01 c-7.67-13.26-14.97-26.87-22.02-40.03c-8.07-15.08-16.43-30.68-25.27-45.54l-0.03-0.05l-0.02,0.06c-1.97,6.9-4.56,13.74-7.29,21 c-7.53,19.94-15.32,40.55-9.23,61.59C935.5,1078.59,938.37,1089.28,941.13,1099.61z M985.69,1032.87 c5.63,10.25,11.44,20.84,17,31.47l0.02,0.04l0.02-0.03c6-7.88,12.3-15.89,18.39-23.65c6.09-7.75,12.39-15.77,18.39-23.65 l0.01-0.01l-0.01-0.01c-18.68-47.82-38.38-96.31-58.55-144.13l-0.03-0.07l-0.02,0.07c-3.31,13.21-7.39,26.4-11.35,39.16 c-5.94,19.13-12.07,38.92-15.67,59.19v0.01v0.01C963.35,992.16,974.71,1012.86,985.69,1032.87z"/> </g> </g> </g> </g>'));
        string memory image1 = string(abi.encodePacked('<text x="-440" y="1650" class="small">Attack: ',attack,' &#9876;</text> <text x="-440" y="1730" class="small">Defense: ',defense,' &#128737;</text> <text x="-440" y="-70" class="small">Dead &#128123;</text> <text x="-440" y="6" class="small">Level: ',_level,' &#127894;</text>'));
        string memory image2 = string(abi.encodePacked(' <text x="405" y="-95" class="small"># ',tokenId,'</text> <text x="1065" y="-70" class="small">Revived: ',_revived,'</text> <text x="295" y="1730" class="small">Kills Count: ',kills.toString(),' &#128128;</text> <text x="1060" y="1730" class="small">Team Rabbit &#129365;</text> </svg>'));
        string memory result = string(abi.encodePacked(image0, image1,image2));
        return result;
    }

    function calculateDaysAlive(uint256 timestamp) internal view returns(uint256) {
        return (((block.timestamp - timestamp) / 86400)+1);
    }

    function calculatePlayerLevel(uint256 timestamp, uint256 kills) internal view returns(uint256) {
        return calculateDaysAlive(timestamp)/10 + kills/2;
    }

    function revivedToString(bool revived) internal pure returns(string memory) {
        if (revived) {
            return "Yes &#128519;";
        } else {
            return "No &#128512;";
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}