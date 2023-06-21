/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface SeaportConduitController {
    function createConduit(
        bytes32 conduitKey,
        address initialOwner
    ) external returns (address);

    function updateChannel(
        address conduit,
        address channel,
        bool isOpen
    ) external;
}

contract RestrictedConduitOwner {
    error Unauthorized();

    event SeaportChannelUnPaused();
    event SeaportChannelPaused();

    event TransferChannelUnPaused();
    event TransferChannelPaused();

    address public immutable SEAPORT_CONDUIT_CONTROLLER_ADDRESS;
    
    mapping(address => bool) public OWNERS;
    
    address public immutable CONDUIT_ADDRESS;

    address public immutable SEAPORT_CHANNEL_ADDRESS;

    address public immutable TRANSFER_CHANNEL_ADDRESS;

    modifier onlyOwner() {
        if (OWNERS[msg.sender] != true) {
            revert Unauthorized();
        }

        _;
    }

    constructor (address seaportConduitControllerAddress, address seaportChannelAddress, address transferChannelAddress, address _initialOwner) {
        OWNERS[_initialOwner] = true;

        SEAPORT_CONDUIT_CONTROLLER_ADDRESS = seaportConduitControllerAddress;

        SeaportConduitController _seaportConduitController = SeaportConduitController(SEAPORT_CONDUIT_CONTROLLER_ADDRESS);

        CONDUIT_ADDRESS = _createConduit(_seaportConduitController);

        SEAPORT_CHANNEL_ADDRESS = seaportChannelAddress;
        _unPauseSeaportChannel(_seaportConduitController);

        TRANSFER_CHANNEL_ADDRESS = transferChannelAddress;
        _unPauseTransferChannel(_seaportConduitController);
    }

    /*** PUBLIC ***/
    
    function pauseSeaportChannel() public onlyOwner {
        SeaportConduitController _seaportConduitController = SeaportConduitController(SEAPORT_CONDUIT_CONTROLLER_ADDRESS);

        _pauseSeaportChannel(_seaportConduitController);
    }

    function unPauseSeaportChannel() public onlyOwner {
        SeaportConduitController _seaportConduitController = SeaportConduitController(SEAPORT_CONDUIT_CONTROLLER_ADDRESS);

        _unPauseSeaportChannel(_seaportConduitController);
    }

    function pauseTransferChannel() public onlyOwner {
        SeaportConduitController _seaportConduitController = SeaportConduitController(SEAPORT_CONDUIT_CONTROLLER_ADDRESS);

        _pauseTransferChannel(_seaportConduitController);
    }

    function unPauseTransferChannel() public onlyOwner {
        SeaportConduitController _seaportConduitController = SeaportConduitController(SEAPORT_CONDUIT_CONTROLLER_ADDRESS);

        _unPauseTransferChannel(_seaportConduitController);
    }

    function setOwner(address _newOwnerAddress, bool _newStatus) public onlyOwner {
        require(_newOwnerAddress != address(0x0), "Invalid address");

        OWNERS[_newOwnerAddress] = _newStatus;
    }

    function getConduitAddress() public view returns (address) {
        return CONDUIT_ADDRESS;
    }

    function getSeaportChannelAddress() public view returns (address) {
        return SEAPORT_CHANNEL_ADDRESS;
    }

    function getTransferChannelAddress() public view returns (address) {
        return TRANSFER_CHANNEL_ADDRESS;
    }

    /*** PRIVATE ***/

    function _unPauseSeaportChannel(SeaportConduitController _seaportConduitController) private {
        _updateChannel(
            _seaportConduitController,
            SEAPORT_CHANNEL_ADDRESS,
            true
        );

        emit SeaportChannelUnPaused();
    }

    function _pauseSeaportChannel(SeaportConduitController _seaportConduitController) private {
        _updateChannel(
            _seaportConduitController,
            SEAPORT_CHANNEL_ADDRESS,
            false
        );

        emit SeaportChannelPaused();
    }

    function _unPauseTransferChannel(SeaportConduitController _seaportConduitController) private {
        _updateChannel(
            _seaportConduitController,
            TRANSFER_CHANNEL_ADDRESS,
            true
        );

        emit TransferChannelUnPaused();
    }

    function _pauseTransferChannel(SeaportConduitController _seaportConduitController) private {
        _updateChannel(
            _seaportConduitController,
            TRANSFER_CHANNEL_ADDRESS,
            false
        );

        emit TransferChannelPaused();
    }

    function _updateChannel(SeaportConduitController _seaportConduitController, address _channelAddress, bool _newStatus) private {
        _seaportConduitController.updateChannel(
            CONDUIT_ADDRESS,
            _channelAddress,
            _newStatus
        );
    }

    function _createConduit(SeaportConduitController _seaportConduitController) private returns (address) {
        bytes32 _conduitKey = _buildConduitKey(address(this));

        return _seaportConduitController.createConduit(
            _conduitKey,
            address(this)
        );
    }

    // Transforms conduit creator address into bytes32 where
    // the first 20 bytes to the left are the address
    // and the remaining 12 bytes to the right are zeroes
    // https://github.com/ProjectOpenSea/seaport/discussions/544
    function _buildConduitKey(address _contractAddress) private pure returns (bytes32 conduitKey) {
        return bytes32(uint256(uint160(_contractAddress)) << 96);
    }
}