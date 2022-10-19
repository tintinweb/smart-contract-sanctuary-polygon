// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ILayerZeroEndpoint {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;
}

contract GelatoLickerSrc {
    uint16 public constant dstChainId = 112; // fantom lz chainId
    ILayerZeroEndpoint public constant lzEndpoint =
        ILayerZeroEndpoint(0x3c2269811836af69497E5F486A85D7316753cf62); // polygon lz endpoint address

    mapping(uint256 => uint256) public lastLicked;

    receive() external payable {}

    //@dev called by Gelato whenever `checker` returns true
    function initiateCCLick(address _dstLicker, uint256 _tokenId)
        external
        payable
    {
        bytes memory lickPayload = abi.encode(_tokenId);

        lastLicked[_tokenId] = block.timestamp;

        lzEndpoint.send{value: address(this).balance}(
            dstChainId,
            abi.encodePacked(address(this), _dstLicker),
            lickPayload,
            payable(this),
            address(0),
            bytes("")
        );
    }

    //@dev called by Gelato check if it is time to call `initiateCCLick`
    function checker(address _dstLicker, uint256 _tokenId)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        if (block.timestamp < lastLicked[_tokenId] + 600) {
            canExec = false;
            execPayload = bytes(
                "CrossChainGelatoLicker: Not time to cross chain lick"
            );
            return (canExec, execPayload);
        }

        canExec = true;
        execPayload = abi.encodeWithSelector(
            this.initiateCCLick.selector,
            _dstLicker,
            _tokenId
        );

        return (canExec, execPayload);
    }
}