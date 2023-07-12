// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

import "./NonblockingLzApp.sol";
import "./ERC20.sol";

contract JadeLayerBridge is NonblockingLzApp, ERC20 {
    
    ILayerZeroEndpoint immutable public endpoint;
    // a map of our connected contracts
    // pause the sendTokens()
    bool public paused;
    bool public isMain;

    event Paused(bool isPaused);
    event SendToChain(uint16 dstChainId, address to, uint256 qty);
    event ReceiveFromChain(uint16 srcChainId, uint64 nonce, uint256 qty);

    constructor(string memory Name,
                string memory Symbol,
                address _endpoint,
                uint16 _chainid,
                uint256 initialSupplyOnMainEndpoint) //End of Constructor arguments.
                
                NonblockingLzApp(_endpoint) ERC20(Name, Symbol) {
                if(_chainid == 109){
                _mint(msg.sender, initialSupplyOnMainEndpoint * 10 ** decimals());
                isMain = true;
                }
                endpoint = ILayerZeroEndpoint(_endpoint);
    }

function AddtrustAddress(uint16 destChainId,address _otherContract) public onlyOwner {
        trustedRemoteLookup[destChainId] = abi.encodePacked(_otherContract, address(this));   
    }

function pauseSendTokens(bool _pause) external onlyOwner {
        paused = _pause;
        emit Paused(_pause);
    }

function _nonblockingLzReceive(uint16 _srcChainId, bytes memory, uint64 nonce, bytes memory _payload) internal override {
    
       (address toAddress, uint amount) = abi.decode(_payload, (address,uint));

       if(isMain){
           _transfer(address(this),toAddress,amount);
       }
       else{
       _mint(toAddress, amount);
       }
       emit ReceiveFromChain(_srcChainId, nonce, amount);
    }

function sendTokens(
        uint16 _dstChainId, // send tokens to this chainId
        address _to, // where to deliver the tokens on the destination chain
        uint256 _qty // how many tokens to send
    ) public payable {
        require(!paused, "OFT: sendTokens() is currently paused");

        // lock if leaving the safe chain, otherwise burn
        if (isMain) {
            // ... transferFrom the tokens to this contract for locking purposes
            _transfer(msg.sender, address(this), _qty);
        } else {
            _burn(msg.sender, _qty);
        }

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(_to, _qty);
        // send LayerZero message

         _lzSend(_dstChainId, payload, payable(_to), address(0x0), bytes(""), msg.value);

         emit SendToChain(_dstChainId,_to,_qty);
    }

function estimateSendTokensFee(uint16 _dstChainId, bool _useZro) external view returns (uint256 nativeFee, uint256 zroFee) {
        return endpoint.estimateFees(_dstChainId, address(this), bytes(""), _useZro, bytes(""));
    }

}