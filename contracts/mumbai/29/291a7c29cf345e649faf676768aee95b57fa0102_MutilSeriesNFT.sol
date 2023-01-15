/**
 *Submitted for verification at polygonscan.com on 2023-01-14
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

contract MutilSeriesNFT {
    struct Base {
        address creator;
        string name;
        uint256 totalSupply;
        mapping(uint256 => address) ownerOf;
    }

    uint256 public seriesNonce = 0;
    mapping(address => Base) public series;
    mapping (address => uint) private _balanceOf;

    event SeriesCreated(address indexed series, address indexed creator);
    event Transfer(address indexed series, address indexed _from, address _to, uint256 indexed _tokenId);
    event Approval(address indexed series, address indexed _owner, address _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed series, address indexed _owner, address indexed _operator, bool _approved);

    function newSeries(string calldata _name) external returns (address){
        seriesNonce++;

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                seriesNonce,
                keccak256("")
            )
        );

        address seriesAddress = address(uint160(uint256(hash)));

        series[seriesAddress].name = _name;
        series[seriesAddress].creator = msg.sender;

        emit SeriesCreated(seriesAddress, msg.sender);

        return seriesAddress;
    }

    function mint(address _to, address _series, uint256 _tokenId) external {
        _balanceOf[_to]++;

        series[_series].ownerOf[_tokenId] = _to;
        series[_series].totalSupply++;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return _balanceOf[_owner];
    }

    function ownerOf(address _series, uint256 _tokenId) external view returns (address) {
        return series[_series].ownerOf[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, address _series, uint256 _tokenId, bytes calldata data) external {

    }

    function safeTransferFrom(address _from, address _to, address _series, uint256 _tokenId) external {

    }

    function transferFrom(address _from, address _to, address _series, uint256 _tokenId) external {
        _transferFrom(_from, _to, _series, _tokenId);
    }

    function _transferFrom(address _from, address _to, address _series, uint256 _tokenId) private {
        require(series[_series].ownerOf[_tokenId] == _from, "from is not token owner");

        series[_series].ownerOf[_tokenId] = _to;
        _balanceOf[_from]--;

        emit Transfer(_series, _from, _to, _tokenId);
    }

    function approve(address _series, uint256 _tokenId, address _approved) external {

    }

    function setApprovalForAll(address _operator, bool _approved) external {

    }

    function setApprovalForSeries(address _operator, address _series, bool _approved) external {
        
    }

    function getApproved(address _series, uint256 _tokenId) external view returns (address) {

    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {

    }

    function isApprovalForSeries(address _operator, address _series, bool _approved) external view returns (bool) {
        
    }
}