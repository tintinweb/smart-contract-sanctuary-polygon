// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PrePrintTrack {
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    // string[] public prePrintCIDs;
    uint256 public prePrintCnt;

    mapping(uint256 => string) public prePrintCIDMap;

    function prePrintCIDs (uint256 _startIndex, uint256 _endIndex) public view returns (string[] memory) {
        require(_startIndex <= _endIndex, "Invalid index range");
        require(_endIndex < prePrintCnt, "Index out of range");
        string[] memory cids = new string[](_endIndex - _startIndex + 1);
        for (uint256 i = _startIndex; i <= _endIndex; i++) {
            cids[i - _startIndex] = prePrintCIDMap[i];
        }
        return cids;
    }

    struct PrePrintInfo {
        address submitAddress;
        uint256 submitTime;
        string keyInfo;
    }

    mapping(string => PrePrintInfo) public prePrints;

    event Submit(
        string _fileCID,
        string keyInfo,
        address indexed _submitAddress,
        uint256 indexed _submitTime,
        string _description
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function submit(
        string memory _fileCID,
        string memory _keyInfo,
        string memory _description
    ) external {
        require(
            prePrints[_fileCID].submitAddress == address(0),
            "The cid of file has existed!"
        );

        uint256 _submitTime = block.timestamp;
        address _submitAddress = msg.sender;

        // prePrintCIDs.push(_fileCID);
        prePrintCIDMap[prePrintCnt] = _fileCID;
        prePrintCnt++;
        prePrints[_fileCID] = PrePrintInfo({
            submitAddress: _submitAddress,
            submitTime: _submitTime,
            keyInfo: _keyInfo
        });

        emit Submit(
            _fileCID,
            _keyInfo,
            _submitAddress,
            _submitTime,
            _description
        );
    }

    receive() external payable {}


    function withdraw() public payable onlyOwner {
        require(address(this).balance > 0);
        owner.transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}