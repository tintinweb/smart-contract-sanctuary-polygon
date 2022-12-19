pragma solidity ^0.8.0;
import './WearableMinimalInterface.sol';
import './Ownable.sol';

contract SantaBurner is Ownable {

    mapping(address=>bool) ApprovedMinters;
    // The address of the santa hat contracts
     IWearable private goldSantaHat;
     IWearable private redSantaHat;
     IWearable private whiteSantaHat;
     IWearable private blueSantaHat;
     IWearable private greenSantaHat;
     IWearable private blackSantaHat;
     IWearable private purpleSantaHat;

     address private burnRecipient;
     address private goldSantaHatAddress;
     address private redSantaHatAddress;
     address private whiteSantaHatAddress;
     address private blueSantaHatAddress;
     address private greenSantaHatAddress;
     address private blackSantaHatAddress;
     address private purpleSantaHatAddress;



    // Events that are emitted when a new Gold santa is minted
    event Mint(address to);

    // Constructor function that sets the transfer contract, transfer ID, and transfer recipient
    constructor(address _goldSantaHat, address _redSantaHat, address _whiteSantaHat, address _blueSantaHat, address _greenSantaHat, address _blackSantaHat, address _purpleSantaHat) public {
        goldSantaHat = IWearable(_goldSantaHat);
        redSantaHat = IWearable(_redSantaHat);
        whiteSantaHat = IWearable(_whiteSantaHat);
        blueSantaHat = IWearable(_blueSantaHat);
        greenSantaHat = IWearable(_greenSantaHat);
        blackSantaHat = IWearable(_blackSantaHat);
        purpleSantaHat = IWearable(_purpleSantaHat);
        burnRecipient = address(0x000000000000000000000000000000000000dEaD);
        goldSantaHatAddress = _goldSantaHat;
        redSantaHatAddress = _redSantaHat;
        whiteSantaHatAddress = _whiteSantaHat;
        blueSantaHatAddress = _blueSantaHat;
        greenSantaHatAddress = _greenSantaHat;
        blackSantaHatAddress = _blackSantaHat;
        purpleSantaHatAddress = _purpleSantaHat;
    }

    function setMinter(address _minter) public onlyOwner returns (bool) {
        ApprovedMinters[_minter] = true;
        return true;
    }

    function revokeMinter(address _minter) public onlyOwner returns (bool) {
        ApprovedMinters[_minter] = false;
        return true;
    }

    // Function to mint a new ERC721 token
    function mint(address _to, uint256 _redId, uint256 _whiteId, uint256 _blueId, uint256 _greenId, uint256 _blackId, uint256 _purpleId) public {
       require(ApprovedMinters[msg.sender] == true, "Not an approved minter");
       require(redSantaHat.ownerOf(_redId) == _to, "Player does not own red santa hat");
       require(whiteSantaHat.ownerOf(_whiteId) == _to, "Player does not own white santa hat");
       require(blueSantaHat.ownerOf(_blueId) == _to, "Player does not own blue santa hat");
       require(greenSantaHat.ownerOf(_greenId) == _to, "Player does not own green santa hat");
       require(blackSantaHat.ownerOf(_blackId) == _to, "Player does not own black santa hat");
       require(purpleSantaHat.ownerOf(_purpleId) == _to, "Player does not own purple santa hat");

       require(redSantaHat.getApproved(_redId) == address(this), "Contract not approved to transfer red santa hat");
       require(whiteSantaHat.getApproved(_whiteId) == address(this), "Contract not approved to transfer white santa hat");
       require(blueSantaHat.getApproved(_blueId) == address(this), "Contract not approved to transfer blue santa hat");
       require(greenSantaHat.getApproved(_greenId) == address(this), "Contract not approved to transfer green santa hat");
       require(blackSantaHat.getApproved(_blackId) == address(this), "Contract not approved to transfer black santa hat");
       require(purpleSantaHat.getApproved(_purpleId) == address(this), "Contract not approved to transfer purple santa hat");

       redSantaHat.safeTransferFrom(_to, burnRecipient, _redId);
       whiteSantaHat.safeTransferFrom(_to, burnRecipient, _whiteId);
       blueSantaHat.safeTransferFrom(_to, burnRecipient, _blueId);
       greenSantaHat.safeTransferFrom(_to, burnRecipient, _greenId);
       blackSantaHat.safeTransferFrom(_to, burnRecipient, _blackId);
       purpleSantaHat.safeTransferFrom(_to, burnRecipient, _purpleId);

       address[] memory recipient = new address[](1);
       recipient[0] = _to;
       uint256[] memory santaHatId = new uint256[](1);
       santaHatId[0] = uint256(0);
       goldSantaHat.issueTokens(recipient, santaHatId);
       emit Mint(_to);
    }

    function isMinter(address _address) external view returns (bool) {
        return ApprovedMinters[_address];
    }

    function setGoldHat(address _address) external onlyOwner {
        goldSantaHat = IWearable(_address);
        goldSantaHatAddress = _address;
    }

    function getGoldHat() external view returns (address) {
        return goldSantaHatAddress;
    }

    function getRedHat() external view returns (address) {
        return redSantaHatAddress;
    }

    function getWhiteHat() external view returns (address) {
        return whiteSantaHatAddress;
    }

    function getBlueHat() external view returns (address) {
        return blueSantaHatAddress;
    }

    function getGreenHat() external view returns (address) {
        return greenSantaHatAddress;
    }

    function getBlackHat() external view returns (address) {
        return blackSantaHatAddress;
    }

    function purpleGoldHat() external view returns (address) {
        return purpleSantaHatAddress;
    }

}