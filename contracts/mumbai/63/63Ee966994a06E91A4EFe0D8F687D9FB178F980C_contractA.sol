pragma solidity ^0.8.0;

library libA{
    struct DiamondStorage{
        uint256 number;
        bool isReentrant;
        address contractOwner;
    
    }

    function diamondStorage() internal pure returns(DiamondStorage storage ds){
        bytes32 storagePosition = keccak256("diamond.storage.libA");
        assembly {
            ds.slot := storagePosition
        }
    }
}

contract contractA{

    modifier nonReentrant() {
        libA.DiamondStorage storage ds = libA.diamondStorage();
        require(libA.diamondStorage().isReentrant == false,"Reentrancy Alert");
        ds.isReentrant = true;
        _;
        ds.isReentrant = false;
        
    }
    event AdminChanged(address indexed previousAdmin,address indexed newAdmin);

    modifier AdminAccess() {
        libA.DiamondStorage storage ds = libA.diamondStorage();
        require(libA.diamondStorage().contractOwner == msg.sender,"Only admin can access these functions");
        _;
    }

    function setter(uint256 _number) external AdminAccess nonReentrant{
        libA.DiamondStorage storage ds = libA.diamondStorage();
        ds.number += _number;

    }
    function getter() external view AdminAccess returns(uint256) {
        return libA.diamondStorage().number;
    }

    function changeAdmin(address _newAdmin) external AdminAccess{
        libA.DiamondStorage storage ds = libA.diamondStorage();
        address previousAdmin = ds.contractOwner;
        ds.contractOwner = _newAdmin;
        emit AdminChanged(previousAdmin,_newAdmin);
    

    }

}