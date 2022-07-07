pragma solidity 0.8.9;

contract TestSettings {
    mapping(uint8 => uint256) public stakePower;

    constructor() {
        stakePower[0] = 0;
        stakePower[1] = 100;
        stakePower[2] = 228;
        stakePower[3] = 430;
        stakePower[4] = 1900;
        stakePower[5] = 18900;
    }

    function getStakePower(uint8 _index) external view returns (uint256) {
        return stakePower[_index];
    }
}