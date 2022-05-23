/**
 *Submitted for verification at polygonscan.com on 2022-05-23
*/

//SPDX-License-Identifier: None
pragma solidity 0.8.0;

library RevertReasonParser {
    function parse(bytes memory data, string memory prefix) internal pure returns (string memory) {
        bytes4 selector;
        assembly {  // solhint-disable-line no-inline-assembly
            selector := mload(add(data, 0x20))
        }

        // 68 = 4-byte selector 0x08c379a0 + 32 bytes offset + 32 bytes length
        if (selector == 0x08c379a0 && data.length >= 68) {
            string memory reason;
            // solhint-disable no-inline-assembly
            assembly {
            // 68 = 32 bytes data length + 4-byte selector + 32 bytes offset
                reason := add(data, 68)
            }
            /*
                revert reason is padded up to 32 bytes with ABI encoder: Error(string)
                also sometimes there is extra 32 bytes of zeros padded in the end:
                https://github.com/ethereum/solidity/issues/10170
                because of that we can't check for equality and instead check
                that string length + extra 68 bytes is less than overall data length
            */
            require(data.length >= 68 + bytes(reason).length, "Invalid revert reason");
            return string(abi.encodePacked(prefix, "Error(", reason, ")"));
        }
        // 36 = 4-byte selector 0x4e487b71 + 32 bytes integer
        else if (selector == 0x4e487b71 && data.length == 36) {
            uint256 code;
            // solhint-disable no-inline-assembly
            assembly {
            // 36 = 32 bytes data length + 4-byte selector
                code := mload(add(data, 36))
            }
            return string(abi.encodePacked(prefix, "Panic(", _toHex(code), ")"));
        }

        return string(abi.encodePacked(prefix, "Unknown(", _toHex(data), ")"));
    }

    function _toHex(uint256 value) private pure returns(string memory) {
        return _toHex(abi.encodePacked(value));
    }

    function _toHex(bytes memory data) private pure returns(string memory) {
        bytes16 alphabet = 0x30313233343536373839616263646566;
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 * i + 2] = alphabet[uint8(data[i] >> 4)];
            str[2 * i + 3] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }
}


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Dex{

    address owner;
    uint tax = 1;
    uint public referrerPercentage = 1;

    constructor()
    {
        owner = msg.sender;
    }

    fallback() payable external{

    }

    receive() payable external{

    }

    function SwapToken(address aggregator, address fromTokenAddress, uint amount, address toTokenAddress, address receiver, address referrerAddress, bytes calldata data) public payable
    {
        require(receiver!=address(0), "Invalid receiver!");
        require(amount>0, "Invalid token amount!");

        uint ethAmount = msg.value;

        if(fromTokenAddress!=address(0))
        {
            IERC20 fromToken = IERC20(fromTokenAddress);
            fromToken.transferFrom(msg.sender, address(this), amount);

            fromToken.approve(aggregator, amount);

            amount = amount - amount*tax/100;
            
            if(referrerPercentage>0 && referrerAddress!=address(0))
            {
                uint referrerAmount = amount * referrerPercentage/100;

                amount -= referrerAmount;

                fromToken.transfer(referrerAddress, referrerAmount);
            }

            ethAmount = 0;
        }
        else
        {
            require(ethAmount>0, "Invalid amount!");

            ethAmount -= ethAmount*tax/100;
            
            if(referrerPercentage>0 && referrerAddress!=address(0))
            {
                uint referrerAmount = ethAmount * referrerPercentage/100;

                ethAmount -= referrerAmount;

                payable(referrerAddress).transfer(referrerAmount);
            }
        }
        
        if(toTokenAddress!=address(0))
        {
            IERC20 toToken = IERC20(toTokenAddress);
            uint initialBalance = toToken.balanceOf(address(this));

            (bool success, bytes memory result) = address(aggregator).call{value: ethAmount}(data);

            if (!success) {
                revert(RevertReasonParser.parse(result, "Dex callBytes failed: "));
            }

            //(uint returnedAmount, uint gasLeft) = abi.decode(result, (uint, uint));
        
            uint newBalance = toToken.balanceOf(address(this));

            uint receivedAmount = newBalance - initialBalance;

            if(receivedAmount>0)
            {
                toToken.transfer(receiver, receivedAmount);
            }
        }
        else
        {
            uint initialBalance = address(this).balance;

            (bool success, bytes memory result) = address(aggregator).call{value: ethAmount}(data);

            if (!success) {
                revert(RevertReasonParser.parse(result, "Dex callBytes failed: "));
            }

            //(uint returnedAmount, uint gasLeft) = abi.decode(result, (uint, uint));
        
            uint newBalance = address(this).balance;

            uint receivedAmount = newBalance - initialBalance;

            if(receivedAmount>0)
            {
                payable(receiver).transfer(receivedAmount);
            }
        }
    }

    function approve(address tokenAddress, address spender, uint amount) public onlyOwner
    {
        IERC20 token = IERC20(tokenAddress);
        token.approve(spender, amount);
    }

    function rescueFunds(address tokenAddress, address receiverAddress, uint amount) public onlyOwner
    {
        if(tokenAddress!=address(0))
        {
            IERC20 token = IERC20(tokenAddress);
            token.transfer(receiverAddress, amount);
        }
        else
        {
            payable(receiverAddress).transfer(amount);
        }
    }

    function updateTax(uint newTax) external onlyOwner
    {
        tax = newTax;
    }

    function updateReferrerPercentage(uint newPercentage) external onlyOwner
    {
        referrerPercentage = newPercentage;
    }

    function transferOwnership(address newOwner) external onlyOwner
    {
        require(newOwner!=address(0), "Zero address cannot be owner!");
        owner = newOwner;
    }
    
    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}