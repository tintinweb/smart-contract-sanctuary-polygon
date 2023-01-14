// SPDX-License-Identifier: MIT
interface uWall {
    function init(
        string memory _n,
        string memory _s,
        uint256 _price,
        uint8 _canMod,
        uint8 _canChange,
        address own
    ) external;
}

contract theArchitectS {
    
    mapping(uint256 => address) public walls;
    mapping(address => string) public wallsbyName;
    mapping(string => address) public nametoWall;
    uint256 public totalWalls;
    event newWall(address,string);
    address public subWall  = 0x9026Be297687FA8d956307EEA3bfC3d805257117;
    address public Wall =0xE2F47Ea26D671087720B8b0435A6e99c173A3D67;

    function createWall(
        string memory _name,
        string memory _symbol,
        uint256 _price,
        uint8 _canMod,
        uint8 _canChange,
        uint8 sWall
    ) public returns (address wall){
        require(nametoWall[_name] == address(0), "Wall claimed");
        /// @solidity memory-safe-assembly
        address implementation = subWall;
        if(sWall == 0){implementation = Wall;
        }
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            wall := create(0, 0x09, 0x37)
        }
        require(wall != address(0), "ERC1167: create failed");
        uWall(wall).init(_name, _symbol, _price, _canMod, _canChange, msg.sender);
        nametoWall[_name] = address(wall);
        walls[totalWalls] = address(wall);
        wallsbyName[address(wall)] = _name;
        totalWalls++;
        emit newWall(address(wall),_name);
        return(address(wall));
    
    }
}