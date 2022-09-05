pragma solidity ^0.8.3;

contract GODPanelsRegistry {

    mapping(uint16 => string) public dnaMappings;
    address public owner;
    mapping(address => bool) public admins;

    event DNA_updated(uint16 _token_id, string _dna);
    event AdminAdded(address _newAdminAddress);
    event AdminRemoved(address _adminAddress);
    event OwnerChanged(address _oldOwnerAddress, address _newOwnerAddress);


    constructor(){
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    function save_DNA(uint16 _tokenId, string memory _dna) external {
        // only owner can call this function
        require(admins[msg.sender], "You don't have authorization to set DNA");
        // DNA can only be set once for each tokenID
        require(keccak256(abi.encodePacked((dnaMappings[_tokenId]))) == keccak256(abi.encodePacked((""))),
         'DNA already set for this token ID');
        // tokenID must be in the range of 1 -> 852
        require(852>=_tokenId, "Invalid tokenId");
        require(_tokenId>=1, "Invalid tokenId");
        // must be valid DNA
        require(check_DNA(_dna), "Invalid DNA");

        dnaMappings[_tokenId] = _dna;
        emit DNA_updated(_tokenId,_dna);
    }
    
    function add_admin(address _newAdminAddress) external {
        require(msg.sender == owner, "You don't have authorization to add admins");
        admins[_newAdminAddress] = true;
        emit AdminAdded(_newAdminAddress);
    }

    function remove_admin(address _adminAddress) external {
        require(msg.sender == owner, "You don't have authorization to remove admins");
        require(_adminAddress != owner, "Cant rewoke admin role of owner");
        admins[_adminAddress] = false;
        emit AdminRemoved(_adminAddress);
    }

    function transfer_owner(address _newOwner) external {
        require(msg.sender == owner, "You don't have authorization to transfer ownership");
        emit OwnerChanged(owner,_newOwner);
        emit AdminAdded(_newOwner);
        admins[_newOwner] = true;
        owner = _newOwner;

    }
   
    function check_DNA (string memory _dna) public pure returns (bool) {
        bytes memory b = bytes(_dna);

        if (b.length != 4) return false;

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];
            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) //a-z
            ) return false;          
        }
        return true;

    }

}