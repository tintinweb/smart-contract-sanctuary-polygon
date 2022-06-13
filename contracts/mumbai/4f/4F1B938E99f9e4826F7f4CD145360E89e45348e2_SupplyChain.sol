// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

contract SupplyChain{

    address immutable general = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address superAdmin;

    error NotApproved();
    error NotCaller();

    constructor(address _superAdmin){
        superAdmin = _superAdmin;
    }

    struct Office {
        bytes32 officeLocation;
        address[] accredictedAddresses;
        uint128 totalReceived;
        uint96 totalSold;
        uint32 amountRemaianing;
    }

    
    struct Headquater {
        uint256 totalReceived;
        uint128 distributed;
        uint128 amountRemaianing;
    }

    uint256 public index = 1;

    mapping (uint256 => Office) public officeTracker;
    mapping (address => Headquater) public headquaterTracker;
    event Approver(address approversAddress);
    event AddressAdded(address youAreAdded);


    modifier onlySuperAdmin(){
        require(msg.sender == superAdmin);
        _;
    }

    function addOffice(bytes32 _location, address[] memory _accredictedAddresses) external onlySuperAdmin {
        Office storage office = officeTracker[index];
        office.officeLocation = _location;
        office.accredictedAddresses = _accredictedAddresses;
        index++;
    }

    function addAccreditedAddress(address _newAddress, uint256 _index) external onlySuperAdmin{
        Office storage office = officeTracker[_index];
        office.accredictedAddresses.push(_newAddress);
        emit AddressAdded(_newAddress);
    }

    function update(uint128 _totalReceived, uint96 _totalSold, uint256 _index) external {
        Office storage office = officeTracker[_index];
        assert(checkAddress(_index));
        uint128 officeTotal = office.totalReceived + _totalReceived;
        office.totalReceived = officeTotal;
        uint96 officeSold = office.totalSold + _totalSold;
        office.totalSold = officeSold;
        uint128 remain = uint128 (officeTotal) - uint96 (officeSold);
        office.amountRemaianing = uint32 (remain);
        emit Approver(msg.sender);
    }

    function updateTotalReceived(uint128 _incomingStock, uint256 _index) public {
        Office storage office  = officeTracker[_index];
        assert(checkAddress(_index));
        office.totalReceived= office.totalReceived + _incomingStock;
        emit Approver(msg.sender);
    }

    function updateTotalSold(uint96 _totalSold, uint256 _index) public {
        Office storage office  = officeTracker[_index];
        assert(checkAddress(_index));
        office.totalSold = office.totalSold - _totalSold;
        emit Approver(msg.sender);
    }

    function headquaterUpdate(uint128 _totalReceived, uint128 _distributed) external onlySuperAdmin{
        Headquater storage head = headquaterTracker[msg.sender];
        uint256 total = head.totalReceived + _totalReceived;
        head.totalReceived = total;
        uint128 distributed = head.distributed + _distributed;
        head.distributed = distributed;
        uint256 remaining = uint256 (total) - uint128 (distributed);
        head.amountRemaianing = uint128 (remaining);
    }

    function checkAddress(uint256 _index) internal view returns (bool status) {
        status;
        Office storage office = officeTracker[_index];
        for (uint256 i; i < office.accredictedAddresses.length; i++) {
            if (office.accredictedAddresses[i] == msg.sender) status = true;
            else revert NotCaller();
        }
    }


}