// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

library TurtleDeadHelper {
    using Strings for uint256;
    function TurtleString(string memory attack, string memory defense, uint256 kills, bool revived, string memory tokenId, uint256 mintTimestamp) public view returns (string memory) {
        string memory _level = calculatePlayerLevel(mintTimestamp, kills).toString();
        string memory _revived = revivedToString(revived);
        string memory image1 = '.small { font: 71px myFont , Times New Roman , Times ; } .big { font: 75px myFont , Times New Roman , Times ; } .st0{fill:#d0d4d7;} </style> <rect class="st0" x="-400" y="-500" width="2850" height="3000"/> <g> <text x="650" y="-140" class="big" fill="#b90e16">Player Eliminated &#128565;</text> <path class="st1" d="M1463.84,1787.06c-10.46-29.65-28.49-55.23-40.11-84.3c48.83,0,98.25,0,147.08,0 c18.02,0,36.04,1.74,53.48-3.49c-38.95-48.83-84.3-93.02-122.66-142.43c-15.7-49.41-25.58-100.57-39.53-150.57 c-8.14-21.51,7.56-41.28,13.95-61.62c-6.98-9.88-13.37-20.35-19.77-30.23c71.51-83.13,143.01-165.68,214.52-248.82 c7.56-8.14,5.81-19.77,7.56-29.65c6.98-145.34,15.7-290.09,23.25-435.43c-1.16-8.14,4.07-13.37,10.46-16.28 c77.9-41.86,155.8-81.39,233.12-123.83c0-61.04,0.58-121.5-0.58-181.96c-115.11-22.67-230.21-43.6-344.74-65.69 c-41.86,40.69-80.81,83.71-121.5,124.99c-5.81,6.98-15.11,12.79-13.95,22.67c7.56,133.71,16.28,267.42,24.42,401.13 c-12.79,13.37-25.58,26.74-40.11,38.95c1.74-10.46,3.49-20.93,5.23-31.39c-81.39-23.84-163.36-45.93-244.75-69.18 c-84.88-22.09-169.17-48.83-254.63-69.18c-173.82,40.69-347.06,84.88-521.47,126.73c-9.88,2.91-21.51,3.49-27.9,13.37 c-93.02,115.69-186.03,230.79-279.05,346.48c20.35,44.76,43.02,88.36,63.95,133.13c-44.18,53.48-92.43,103.48-135.45,158.13 c7.56,2.33,15.11,2.91,22.67,2.33c61.04-4.65,122.66-10.46,183.71-15.11c11.05,23.25,21.51,46.51,35.46,68.02 c-44.76,47.09-88.36,95.34-132.55,143.59c-8.72,8.14,2.91,18.6,5.81,26.74c18.6,28.49,31.39,61.04,52.9,87.78 c63.37,1.74,126.73-1.16,190.1,0.58c22.09,16.28,38.37,39.53,60.46,55.81c107.55,2.33,215.1,0.58,322.65,1.16 c-1.74-8.72-3.49-17.44-6.98-25.58c-25.58-62.79-51.74-125.57-77.32-188.36c73.25,0,146.5,1.16,219.75-0.58 c61.04-13.37,120.92-30.81,182.54-43.6c-11.05,28.49-25.58,55.23-37.79,83.13c-7.56,13.37,4.07,26.74,8.14,39.53 c20.93,47.67,40.69,95.92,62.2,143.01C1252.23,1787.64,1358.04,1786.48,1463.84,1787.06z M1444.08,1773.69 c-91.27,2.33-183.12,1.16-274.4,0c63.95-53.48,127.31-106.97,192.43-158.71C1391.17,1666.72,1418.5,1720.2,1444.08,1773.69z M436.6,1471.97c-40.69-8.14-82.55-12.79-122.66-24.42c27.9-25,57.55-48.83,88.95-69.18c13.95,2.91,26.74,11.05,38.95,18.02 c38.37,22.09,77.32,42.44,116.27,63.95c26.16,15.12,55.23,26.16,79.06,45.93C569.73,1500.45,503.46,1483.01,436.6,1471.97z M488.92,1494.64c-33.14,54.65-66.27,109.87-101.74,163.36c-0.58-60.46-0.58-120.92-0.58-180.8 C421.49,1479.53,455.21,1487.08,488.92,1494.64z M425.56,1373.14c77.32-16.28,155.8-26.74,233.12-40.69 c89.53-14.53,179.05-31.39,269.16-44.76c-52.9,55.81-111.04,105.8-166.27,159.29c-24.42,23.25-48.83,46.51-74.41,68.02 C598.8,1469.64,512.18,1421.97,425.56,1373.14z M746.46,1156.3c61.62,39.53,124.41,75.57,184.87,116.27 c-144.17,26.74-288.93,48.83-433.1,74.41c-22.67,3.49-44.76,6.98-67.44,8.72c84.3-71.51,172.66-138.36,258.12-208.7 c6.4-4.07,12.21-12.21,20.93-11.63C723.21,1140.6,734.83,1148.74,746.46,1156.3z M722.63,1124.32 c197.08-94.76,394.73-187.19,592.39-280.79c30.81-14.53,59.88-32.56,93.02-40.69c-43.6,50.58-94.18,95.34-140.69,144.17 c-93.6,92.43-183.12,188.94-276.14,281.37c-12.79,12.79-23.84,26.74-38.95,36.62c-13.37-0.58-24.42-11.05-36.04-16.86 C851.68,1207.46,785.41,1167.92,722.63,1124.32z M845.29,1385.35c21.51-20.93,43.02-42.44,65.69-62.2 c20.93-18.02,38.95-41.28,66.27-50c97.08-31.39,192.43-69.18,290.67-97.67c-158.13,96.5-319.16,188.36-478.45,282.53 c-12.21,7.56-25.58,14.53-38.95,20.35C777.27,1442.9,813.9,1416.16,845.29,1385.35z M1221.42,1224.32 c51.74,1.74,102.9,5.23,154.64,9.3c-32.56,36.04-66.85,70.34-101.74,104.06C1255.14,1300.47,1238.28,1262.68,1221.42,1224.32z M1263.86,1348.14c-31.39,26.16-62.78,51.74-94.76,76.74c11.63-62.79,28.49-124.99,43.02-187.19 C1232.47,1273.15,1249.32,1310.35,1263.86,1348.14z M1390.59,1238.27c22.09,33.72,45.93,65.69,65.69,100.57 c-55.23,1.74-111.04,3.49-166.27,2.91C1321.41,1305.7,1356.87,1272.57,1390.59,1238.27z M1419.08,1256.29 c-8.14-11.05-16.28-22.09-23.84-33.14c-52.32-6.39-105.22-4.07-156.96-12.79c29.65-22.67,64.53-37.79,95.34-58.13 c12.21-7.56,13.95-23.25,18.6-35.46c25,2.91,49.41,9.88,73.25,18.02C1425.47,1175.48,1420.24,1215.6,1419.08,1256.29z M1091.2,1294.08c36.04-20.35,70.92-43.02,108.13-61.04c-15.11,66.85-27.32,134.29-47.67,199.98c-30.23-9.3-59.3-23.25-88.36-35.46 c-27.32-11.63-56.39-20.93-81.97-36.62C1016.2,1336.51,1054.57,1316.75,1091.2,1294.08z M1269.09,1360.35 c15.12,33.14,23.84,68.02,37.79,101.74c13.37,38.95,30.23,76.74,39.53,116.85c-31.39-17.44-57.55-43.02-86.62-63.37 c-30.23-25-62.2-47.09-91.27-72.67C1201.07,1414.42,1234.21,1386.51,1269.09,1360.35z M1478.37,1566.73 c-22.09,33.14-48.25,63.95-76.16,92.43c-11.63-16.86-22.67-34.88-27.9-54.65c-1.16-13.95,7.56-25.58,12.79-37.21 C1417.91,1564.98,1448.14,1564.98,1478.37,1566.73z M1392.34,1553.36c8.14-21.51,16.28-43.02,25-64.53 c23.84,18.02,42.44,41.86,61.62,64.53C1449.89,1555.68,1420.82,1555.68,1392.34,1553.36z M1600.46,1691.14 c-61.62,1.16-123.24,1.74-184.87-0.58c-2.33-5.23-5.23-10.46-6.98-15.7c27.9-35.46,56.39-70.92,87.2-104.06 C1531.28,1610.33,1567.9,1649.28,1600.46,1691.14z M1482.44,1535.34c-19.18-17.44-37.79-35.46-52.9-56.39 c-5.81-5.81-1.74-13.95,0.58-20.35c5.81-15.7,13.37-30.81,21.51-45.34C1462.1,1453.95,1473.72,1494.06,1482.44,1535.34z M1458.03,1353.37c-15.7,48.25-37.79,93.6-55.81,141.27c-13.37,29.07-22.09,60.46-38.37,88.36 c-27.32-75.57-54.65-151.73-81.97-227.31C1340.6,1353.96,1399.31,1351.05,1458.03,1353.37z M1616.73,1110.37 c-56.39,63.37-110.46,129.06-167.43,192.43c-8.72-12.21-20.35-24.42-18.02-40.69c1.74-42.44,4.07-84.88,7.56-127.31 c33.14-12.21,67.44-20.35,101.15-31.39c34.3-9.88,68.02-23.25,104.06-29.65C1635.92,1087.12,1626.62,1099.33,1616.73,1110.37z M1666.73,1035.38c-56.39-88.36-108.13-179.64-163.36-268.58c28.49-30.81,62.2-55.81,93.02-84.29 c30.81-26.16,59.88-55.23,92.43-79.64C1684.17,747.03,1673.13,891.2,1666.73,1035.38z M1510.35,740.64 c19.18-77.32,47.67-152.31,69.18-228.47c12.79,4.07,23.84,12.21,34.88,20.35c23.25,18.6,49.41,34.3,72.67,53.48 C1628.36,637.74,1570.81,691.22,1510.35,740.64z M1698.12,577.28c-33.72-23.25-68.6-45.93-99.41-73.25 c66.27-8.14,132.55-16.86,198.82-23.25c33.72-3.49,66.27-9.88,99.99-9.3C1831.83,508.1,1764.98,542.4,1698.12,577.28z M1592.9,490.08c31.39-56.39,65.69-111.04,100.57-165.68c44.76,22.09,86.62,49.41,130.8,73.83c30.23,18.6,62.2,33.72,91.27,54.65 C1808,466.82,1700.45,480.19,1592.9,490.08z M1932.41,444.73c-46.51-23.25-90.69-51.74-136.04-76.74 c-27.32-16.86-57.55-30.23-81.97-50.58c72.67-8.72,145.34-19.18,218.59-26.74C1934.15,341.83,1934.15,393.57,1932.41,444.73z M1812.65,265.1c26.74,5.23,54.07,8.14,79.64,17.44c-65.69,8.72-131.97,17.44-198.82,25c-25.58-26.16-50.58-52.9-74.99-79.64 C1683.01,240.68,1747.54,252.31,1812.65,265.1z M1601.04,228.47c26.16,26.16,51.74,52.9,76.16,80.81 c-62.2,13.37-124.41,25.58-187.77,34.88C1525.46,304.63,1563.25,266.26,1601.04,228.47z M1677.19,323.81 c-31.97,55.23-65.11,109.87-99.99,163.36c-32.56-41.86-66.85-83.13-94.76-128.48C1547.55,347.65,1611.5,333.11,1677.19,323.81z M1478.37,377.29c22.09,26.74,41.28,55.81,62.79,82.55c9.88,13.37,21.51,26.16,28.49,41.28c-4.07,26.16-15.11,50.58-22.09,75.57 c-16.86,50-29.65,101.74-49.41,151.15C1492.91,611,1481.86,494.15,1478.37,377.29z M1497.56,784.24 c23.83,30.81,41.28,66.27,62.78,99.41c32.56,56.97,69.18,111.04,99.41,168.59c-36.62,14.53-74.99,23.84-112.2,35.46 c-35.46,10.46-69.76,23.84-105.8,30.81C1458.03,1006.89,1480.12,895.86,1497.56,784.24z M1483.03,790.05 c-14.53,111.04-37.21,220.91-54.07,331.95c-25-4.65-49.41-10.46-72.09-22.09c23.84-83.71,51.16-166.26,74.99-249.98 C1438.84,823.77,1458.61,802.26,1483.03,790.05z M1366.76,1023.75c-11.63,37.79-21.51,76.74-36.04,113.94 c-62.79,23.84-126.73,44.18-189.52,66.85c-52.9,17.44-104.64,39.53-158.71,52.9c41.28-48.83,88.95-90.69,132.55-137.2 c84.3-86.04,168.59-172.66,254.05-257.54c20.35-20.35,39.53-42.44,62.2-60.46C1413.85,877.25,1388.85,949.92,1366.76,1023.75z M960.4,642.97c127.9,35.46,255.79,71.51,383.69,106.97c27.9,7.56,56.39,14.53,83.71,24.42c-23.84,15.12-49.41,25-74.41,37.21 c-201.15,95.92-402.29,191.26-603.44,286.02c-8.14,3.49-16.28,6.39-25,9.88c9.3-26.16,23.25-50,35.46-74.41 c55.23-107.55,109.87-215.68,164.52-323.81C936.56,687.15,945.86,663.9,960.4,642.97z M942.96,645.3 c-76.74,156.38-157.54,310.44-235.44,466.24c-15.7-12.79-27.32-29.07-40.11-44.76c-79.64-98.25-161.03-195.91-240.68-294.74 C598.22,727.85,770.88,687.15,942.96,645.3z M218.6,1020.84c65.69-80.81,129.64-162.78,196.49-242.42 c93.6,112.2,186.03,225.56,277.88,338.92c-181.96,0.58-364.5-3.49-546.46-4.07C168.02,1080.72,195.34,1051.66,218.6,1020.84z M408.12,1127.81c93.02,1.16,186.03,0.58,279.63,2.33c-31.97,30.23-68.02,55.81-101.74,83.71 c-61.04,48.25-120.34,98.83-182.54,145.92c-75.58-68.02-149.41-137.78-224.4-206.38c-8.72-8.14-16.86-16.86-24.42-26.16 C238.95,1123.74,323.82,1127.23,408.12,1127.81z M80.82,1396.98c21.51-29.65,47.09-55.23,70.92-83.13 c15.12-16.86,27.9-36.04,47.09-48.25c-7.56,41.86-23.84,82.55-37.79,122.66C136.05,1398.72,107.56,1395.23,80.82,1396.98z M175,1390c9.88-33.14,20.93-66.27,31.97-98.83c18.02,29.07,33.14,60.46,45.93,92.43C226.74,1387.09,201.16,1388.84,175,1390z M207.55,1258.61c-16.28-35.46-37.21-69.18-49.41-106.39c67.44,59.88,133.13,122.08,199.98,183.12 c12.21,10.46,24.42,20.93,33.14,34.88c-30.81,23.84-61.04,48.25-94.18,69.76C264.53,1381.28,237.2,1319.07,207.55,1258.61z M314.52,1462.67c19.77,2.33,39.53,5.81,59.3,9.88c0.58,12.21,5.81,30.23-10.46,34.88c-54.65,27.32-108.13,56.39-163.94,80.81 C236.62,1545.22,273.83,1502.2,314.52,1462.67z M373.24,1594.05c-56.97,4.07-113.36,9.88-170.33,10.46 c55.23-31.97,113.36-59.3,170.92-87.2C374.4,1542.89,374.4,1568.47,373.24,1594.05z M176.16,1619.05 c66.27-2.91,132.55-10.46,199.4-10.46c-1.74,8.72,1.16,20.93-9.88,24.42c-45.93,25.58-91.85,50.58-138.36,74.41 C207.55,1679.51,191.86,1649.28,176.16,1619.05z M254.64,1709.16c37.79-24.42,77.9-44.76,118.01-64.53 c2.91,16.28-1.16,35.46,11.05,48.25c4.65,5.81,9.3,11.05,13.95,16.86C349.98,1710.9,302.31,1711.48,254.64,1709.16z M396.49,1686.49c62.2-9.3,124.41-13.37,187.19-21.51c35.46-2.91,70.92-9.88,106.39-8.72c-12.21,9.3-25.58,16.86-39.53,23.25 c-58.13,27.9-114.53,58.72-173.24,86.04C448.23,1741.13,421.49,1714.97,396.49,1686.49z M780.18,1767.29 c-91.27,0.58-183.12,1.16-274.98-0.58c74.99-39.53,151.73-76.74,228.47-114.53C749.95,1689.97,765.65,1728.34,780.18,1767.29z M395.33,1673.7c11.05-26.16,27.9-49.41,42.44-73.25c22.09-34.3,42.44-69.18,64.53-103.48c33.72,7.56,74.41,3.49,99.99,30.81 c38.95,37.79,81.39,72.67,119.76,111.04C613.33,1649.86,504.62,1662.65,395.33,1673.7z M716.23,1611.49 c-15.11-9.88-29.65-21.51-42.44-33.72c-20.35-20.35-43.6-37.79-62.79-59.3c25,1.74,50,5.23,73.83,12.79 C695.88,1557.43,707.51,1584.17,716.23,1611.49z M705.18,1552.78c-2.33-8.72-4.65-18.02-6.39-27.32 c20.35-12.79,41.86-26.16,63.95-37.21c43.6,21.51,89.53,38.37,130.22,64.53C830.17,1555.68,767.39,1555.68,705.18,1552.78z M924.93,1551.03c-49.41-22.09-97.67-45.34-145.92-69.18c23.84-22.09,54.65-34.3,81.39-51.74c33.14-17.44,63.37-38.95,96.5-56.39 c9.3-5.81,19.18,1.74,28.49,4.65c-5.23,22.67-13.37,44.76-22.09,66.27C949.93,1480.11,940.05,1516.73,924.93,1551.03z M1062.71,1520.8c-40.69,8.72-80.23,22.09-121.5,27.9c15.7-55.23,38.37-108.71,56.97-163.94c50,17.44,98.25,41.28,148.24,60.46 c-5.81,20.35-13.37,40.69-26.16,58.72C1102.24,1513.24,1081.9,1515.57,1062.71,1520.8z M1159.22,1453.95 c52.32,36.04,100.57,77.32,151.15,115.11c12.21,8.72,24.42,18.6,35.46,29.07c-85.46,4.65-171.5,8.14-256.95,8.72 C1111.55,1555.1,1134.8,1504.52,1159.22,1453.95z M1181.31,1616.14c54.65-2.91,109.29-4.65,163.36-4.65 c-33.72,30.23-70.34,57.55-104.64,87.2c-29.65,23.25-56.39,49.41-87.2,70.34c-24.42-47.67-43.6-98.25-64.53-147.66 C1119.1,1616.14,1150.5,1617.89,1181.31,1616.14z"/> </g>';
        string memory image2 = string(abi.encodePacked('<text x="-310" y="2180" class="small">Attack: ',attack,' &#9876;</text> <text x="-310" y="2300" class="small">Defense: ',defense,' &#128737;</text> <text x="-310" y="-255" class="small">Dead &#128123;</text> '));
        string memory image3 = string(abi.encodePacked('<text x="-310" y="-145" class="small">Level: ',_level,' &#127894;</text> <text x="900" y="-300" class="small"># ',tokenId,'</text> <text x="1840" y="-260" class="small">Revived: ',_revived,' </text> <text x="715" y="2300" class="small">Kills Count: ',kills.toString(),' &#128128;</text> <text x="1840" y="2300" class="small">Team Turtle &#129388;</text> </svg>'));
        string memory result = string(abi.encodePacked(image1, image2, image3));
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