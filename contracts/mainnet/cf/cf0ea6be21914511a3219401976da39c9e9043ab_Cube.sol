/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IContract {
    function handleRotateEdgesFrontClockwise() external;
    function handleRotateEdgesFrontCounterClockwise() external;
    function handleRotateEdgesBackClockwise() external;
    function handleRotateEdgesBackCounterClockwise() external;
    function handleRotateEdgesLeftClockwise() external;
    function handleRotateEdgesLeftCounterClockwise() external;
}

/**
 * @title Cube
 */
contract Cube {

    uint8[][] cubeState = [
        [0,0,0,0,0,0,0,0,0],
        [1,1,1,1,1,1,1,1,1],
        [2,2,2,2,2,2,2,2,2],
        [3,3,3,3,3,3,3,3,3],
        [4,4,4,4,4,4,4,4,4],
        [5,5,5,5,5,5,5,5,5]
    ];

    address owner = msg.sender;
    address operationContract;

    modifier onlyOperationContracts {
        require(msg.sender == operationContract);
        _;
    }

    function setCubeState(uint8[][] memory data) external onlyOperationContracts {
        cubeState = data;
    }

    function setOperationContract(address contractAddr) external {
        require(msg.sender == owner);
        operationContract = contractAddr;
    }

    // Special thanks to Nick Rogers (@rogersanick) for the methods
    // https://github.com/rogersanick/rubikscubesolver/blob/master/client/src/rubiksHelpers/cube-functions.js

    function handleRotateEdgesFrontClockwise() external {
        IContract(operationContract).handleRotateEdgesFrontClockwise();
    }

    function handleRotateEdgesFrontCounterClockwise() external {
        uint8 temp1 = cubeState[1][0];
        uint8 temp2 = cubeState[1][1];
        uint8 temp3 = cubeState[1][2];
        cubeState[1][0] = cubeState[2][2];
        cubeState[1][1] = cubeState[2][5];
        cubeState[1][2] = cubeState[2][8];
        cubeState[2][2] = cubeState[5][8];
        cubeState[2][5] = cubeState[5][7];
        cubeState[2][8] = cubeState[5][6];
        cubeState[5][8] = cubeState[4][6];
        cubeState[5][7] = cubeState[4][3];
        cubeState[5][6] = cubeState[4][0];
        cubeState[4][6] = temp1;
        cubeState[4][3] = temp2;
        cubeState[4][0] = temp3;
    }

    function handleRotateEdgesBackClockwise() external {
        uint8 temp1 = cubeState[1][6];
        uint8 temp2 = cubeState[1][7];
        uint8 temp3 = cubeState[1][8];
        cubeState[1][6] = cubeState[2][0];
        cubeState[1][7] = cubeState[2][3];
        cubeState[1][8] = cubeState[2][6];
        cubeState[2][0] = cubeState[5][2];
        cubeState[2][3] = cubeState[5][1];
        cubeState[2][6] = cubeState[5][0];
        cubeState[5][2] = cubeState[4][8];
        cubeState[5][1] = cubeState[4][5];
        cubeState[5][0] = cubeState[4][2];
        cubeState[4][8] = temp1; 
        cubeState[4][5] = temp2; 
        cubeState[4][2] = temp3; 
    }

    function handleRotateEdgesBackCounterClockwise() external {
        uint8 temp1 = cubeState[2][0];
        uint8 temp2 = cubeState[2][3];
        uint8 temp3 = cubeState[2][6];
        cubeState[2][0] = cubeState[1][6];
        cubeState[2][3] = cubeState[1][7];
        cubeState[2][6] = cubeState[1][8];
        cubeState[1][6] = cubeState[4][8];
        cubeState[1][7] = cubeState[4][5];
        cubeState[1][8] = cubeState[4][2];
        cubeState[4][8] = cubeState[5][2];
        cubeState[4][5] = cubeState[5][1];
        cubeState[4][2] = cubeState[5][0];
        cubeState[5][2] = temp1;
        cubeState[5][1] = temp2;
        cubeState[5][0] = temp3;
    }

    // ROTATE LEFT FACE EDGES
    function handleRotateEdgesLeftClockwise() external {
        uint8 temp1 = cubeState[1][2];
        uint8 temp2 = cubeState[1][5];
        uint8 temp3 = cubeState[1][8];
        cubeState[1][2] = cubeState[3][6];
        cubeState[1][5] = cubeState[3][3];
        cubeState[1][8] = cubeState[3][0];
        cubeState[3][6] = cubeState[5][2];
        cubeState[3][3] = cubeState[5][5];
        cubeState[3][0] = cubeState[5][8];
        cubeState[5][2] = cubeState[0][2];
        cubeState[5][5] = cubeState[0][5];
        cubeState[5][8] = cubeState[0][8];
        cubeState[0][2] = temp1; 
        cubeState[0][5] = temp2; 
        cubeState[0][8] = temp3; 
    }

    function handleRotateEdgesLeftCounterClockwise() external {
        uint8 temp1 = cubeState[1][2];
        uint8 temp2 = cubeState[1][5];
        uint8 temp3 = cubeState[1][8];
        cubeState[1][2] = cubeState[0][2];
        cubeState[1][5] = cubeState[0][5];
        cubeState[1][8] = cubeState[0][8];
        cubeState[0][2] = cubeState[5][2];
        cubeState[0][5] = cubeState[5][5];
        cubeState[0][8] = cubeState[5][8];
        cubeState[5][2] = cubeState[3][6];
        cubeState[5][5] = cubeState[3][3];
        cubeState[5][8] = cubeState[3][0];
        cubeState[3][6] = temp1;
        cubeState[3][3] = temp2;
        cubeState[3][0] = temp3;
    }

    // ROTATE RIGHT FACE EDGES
    function handleRotateEdgesRightClockwise() external {
        uint8 temp1 = cubeState[1][0];
        uint8 temp2 = cubeState[1][3];
        uint8 temp3 = cubeState[1][6];
        cubeState[1][0] = cubeState[0][0];
        cubeState[1][3] = cubeState[0][3];
        cubeState[1][6] = cubeState[0][6];
        cubeState[0][0] = cubeState[5][0];
        cubeState[0][3] = cubeState[5][3];
        cubeState[0][6] = cubeState[5][6];
        cubeState[5][0] = cubeState[3][8];
        cubeState[5][3] = cubeState[3][5];
        cubeState[5][6] = cubeState[3][2];
        cubeState[3][8] = temp1; 
        cubeState[3][5] = temp2; 
        cubeState[3][2] = temp3; 
    }

    function handleRotateEdgesRightCounterClockwise() external {
        uint8 temp1 = cubeState[1][6];
        uint8 temp2 = cubeState[1][3];
        uint8 temp3 = cubeState[1][0];
        cubeState[1][6] = cubeState[3][2];
        cubeState[1][3] = cubeState[3][5];
        cubeState[1][0] = cubeState[3][8];
        cubeState[3][2] = cubeState[5][6];
        cubeState[3][5] = cubeState[5][3];
        cubeState[3][8] = cubeState[5][0];
        cubeState[5][6] = cubeState[0][6];
        cubeState[5][3] = cubeState[0][3];
        cubeState[5][0] = cubeState[0][0];
        cubeState[0][6] = temp1;
        cubeState[0][3] = temp2;
        cubeState[0][0] = temp3;
    }

    // ROTATE TOP FACE EDGES
    function handleRotateEdgesUpClockwise() external {
        uint8 temp1 = cubeState[0][8];
        uint8 temp2 = cubeState[0][7];
        uint8 temp3 = cubeState[0][6];
        cubeState[0][8] = cubeState[2][8];
        cubeState[0][7] = cubeState[2][7];
        cubeState[0][6] = cubeState[2][6];
        cubeState[2][8] = cubeState[3][8];
        cubeState[2][7] = cubeState[3][7];
        cubeState[2][6] = cubeState[3][6];
        cubeState[3][8] = cubeState[4][8];
        cubeState[3][7] = cubeState[4][7];
        cubeState[3][6] = cubeState[4][6];
        cubeState[4][8] = temp1; 
        cubeState[4][7] = temp2; 
        cubeState[4][6] = temp3; 
    }

    function handleRotateEdgesUpCounterClockwise() external {
        uint8 temp1 = cubeState[0][8];
        uint8 temp2 = cubeState[0][7];
        uint8 temp3 = cubeState[0][6];
        cubeState[0][8] = cubeState[4][8];
        cubeState[0][7] = cubeState[4][7];
        cubeState[0][6] = cubeState[4][6];
        cubeState[4][8] = cubeState[3][8];
        cubeState[4][7] = cubeState[3][7];
        cubeState[4][6] = cubeState[3][6];
        cubeState[3][8] = cubeState[2][8];
        cubeState[3][7] = cubeState[2][7];
        cubeState[3][6] = cubeState[2][6];
        cubeState[2][8] = temp1;
        cubeState[2][7] = temp2;
        cubeState[2][6] = temp3;
    }

    // ROTATE BOTTOM FACE EDGES

    function handleRotateEdgesDownClockwise() external {
        uint8 temp1 = cubeState[0][2];
        uint8 temp2 = cubeState[0][1];
        uint8 temp3 = cubeState[0][0];
        cubeState[0][2] = cubeState[4][2];
        cubeState[0][1] = cubeState[4][1];
        cubeState[0][0] = cubeState[4][0];
        cubeState[4][2] = cubeState[3][2];
        cubeState[4][1] = cubeState[3][1];
        cubeState[4][0] = cubeState[3][0];
        cubeState[3][2] = cubeState[2][2];
        cubeState[3][1] = cubeState[2][1];
        cubeState[3][0] = cubeState[2][0];
        cubeState[2][2] = temp1;
        cubeState[2][1] = temp2;
        cubeState[2][0] = temp3;
    }


    function handleRotateEdgesDownCounterClockwise() external {
        uint8 temp1 = cubeState[0][2];
        uint8 temp2 = cubeState[0][1];
        uint8 temp3 = cubeState[0][0];
        cubeState[0][2] = cubeState[2][2];
        cubeState[0][1] = cubeState[2][1];
        cubeState[0][0] = cubeState[2][0];
        cubeState[2][2] = cubeState[3][2];
        cubeState[2][1] = cubeState[3][1];
        cubeState[2][0] = cubeState[3][0];
        cubeState[3][2] = cubeState[4][2];
        cubeState[3][1] = cubeState[4][1];
        cubeState[3][0] = cubeState[4][0];
        cubeState[4][2] = temp1; 
        cubeState[4][1] = temp2; 
        cubeState[4][0] = temp3; 
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieveCubeState() external view returns (uint8[][] memory){
        return cubeState;
    }

    function solved() external view returns (bool) {
        for (uint8 i=0; i < 6; i++) {
            uint8 initialElement = cubeState[i][0];
            for (uint8 j=1; j < 6; j++) {
                if (initialElement != cubeState[i][j]) {
                    return false;
                }
            }
        }
        return true;
    }
}