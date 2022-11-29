//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "./console.sol";

import "./Ownable.sol";

interface IERC20 {
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Router {
	function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
	function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
	function token0() external view returns (address);
	function token1() external view returns (address);
	function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
}

contract Arb is Ownable {

	struct SwapBufferEntry {
		uint256 startBalance;
		address router;
		address tokenIn;
		address tokenOut;
		uint256 amount;
	}

	SwapBufferEntry[] buffer;

	error Log(string reason);
	error LogBytes(bytes reason);
	error ErrorUint(uint errCode);

	event SwapPerformed(address router, address _tokenIn, address _tokenOut, uint256 _amount);
	event SwapBuffered(SwapBufferEntry entry);
	event ClosedDelayedSwap(uint256 amount);
	event ErrorOccurred();
	event ReachedEnd();
	event StringLog(string reason, int256);
	event UIntLog(string reason, uint256);
	event AmountsOut(uint[] amounts);

	function swap(address router, address _tokenIn, address _tokenOut, uint256 _amount) private returns(bool wasSuccessful) {
		require(_amount >= 1, "Amount must be greater than or equal to one.");
        
        bool approvalSuccessful = false;
        
		try IERC20(_tokenIn).approve(router, _amount) returns (bool success) {
            approvalSuccessful = success;
			emit StringLog("Swap approved for amount", int(_amount));
			emit UIntLog("Uint version", _amount);
		} /*catch Error(string memory reason) {
				// catch failing revert() and require()
				revert Log({reason: reason});
		} catch (bytes memory reason) {
				// catch failing assert()
				revert LogBytes({reason: reason});
		} catch Panic(uint errorCode) {
				revert ErrorUint({errCode: errorCode});
		}*/ catch {
             //revert Log("Caught an exception in swap:approve");
        }
        
        require(approvalSuccessful, "The Swap Approval was unsuccessful");

        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        uint deadline = (block.timestamp + 3600)*1000;
        
        try IUniswapV2Router(router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline)
            returns(uint[] memory amounts) {
			emit AmountsOut(amounts);
            emit SwapPerformed(router, _tokenIn, _tokenOut, _amount);
            wasSuccessful = true;
			emit StringLog("Successfully completed the swap.", 1);
        } catch {
			wasSuccessful = false;
            //revert Log("Caught an exception in swap:swapExactTokensForTokens");
        }

		if (wasSuccessful) {
			emit StringLog("Post-Try Catch -- swap:wasSuccessful: true",1);
		} else {
			emit StringLog("Post-Try Catch -- swap:wasSuccessful: false",0);
		}
        return wasSuccessful;
	}

	function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256) {
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint256 result = 0;
		try IUniswapV2Router(router).getAmountsOut(_amount, path) returns (uint256[] memory amountOutMins) {
			result = amountOutMins[path.length -1];
		} catch {
		}
		// uint256[] memory amountOutMins = IUniswapV2Router(router).getAmountsOut(_amount, path);
		return result;
	}

	function estimateDualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external view returns (uint256) {
		uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
		uint256 amtBack2 = getAmountOutMin(_router2, _token2, _token1, amtBack1);
		return amtBack2;
	}

	function checkBufferStatus() external view returns (uint256) {
		if (buffer.length == 0) {
			return 1337;
		}
		for (uint i = 0; i < buffer.length; i += 1) {
			uint256 amountBack = getAmountOutMin(buffer[i].router, buffer[i].tokenIn, buffer[i].tokenOut, buffer[i].amount);
			if (buffer[i].startBalance < amountBack) {
				return i;
			}
		}
		return 1337;
	}

	function checkBufferLength() external view returns (uint256) {
		return buffer.length;
	}

	function closeSwapBufferEntry(uint index) external onlyOwner {
		require(buffer.length > 0, "Buffer length is 0.");
		require(index < buffer.length, "Index is outside of buffer length.");
		swap(buffer[index].router, buffer[index].tokenIn, buffer[index].tokenOut, buffer[index].amount);
		buffer.pop();
	}

	function bufferIndexView(uint index) external view returns (address router, address tokenIn, address tokenOut, uint256 amount) {
		return (buffer[index].router, buffer[index].tokenIn, buffer[index].tokenOut, buffer[index].amount);
	}

	function flushBuffer() external onlyOwner {
		for (uint i = 0; i < buffer.length; i += 1) {
			buffer.pop();
		}
	}
	
	function dualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external onlyOwner {
		uint startBalance = IERC20(_token1).balanceOf(address(this));
		uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
		swap(_router1,_token1, _token2,_amount);
		uint token2Balance = IERC20(_token2).balanceOf(address(this));
		uint tradeableAmount = token2Balance - token2InitialBalance;
		swap(_router2,_token2, _token1,tradeableAmount);
		uint endBalance = IERC20(_token1).balanceOf(address(this));
		require(endBalance > startBalance, "Trade Reverted, No Profit Made");
	}

	function dualDexTradeHold(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external onlyOwner {
		uint startBalance = IERC20(_token1).balanceOf(address(this));
		uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
		swap(_router1,_token1, _token2,_amount);
		uint token2Balance = IERC20(_token2).balanceOf(address(this));
		uint tradeableAmount = token2Balance - token2InitialBalance;
		SwapBufferEntry memory entry = SwapBufferEntry(startBalance, _router2,_token2, _token1,tradeableAmount);
		buffer.push(entry);
		emit SwapBuffered(entry);
	}

	function estimateTriDexTrade(address _router1, address _router2, address _router3, address _token1, address _token2, address _token3, uint256 _amount) external view returns (uint256) {
		uint amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
		uint amtBack2 = getAmountOutMin(_router2, _token2, _token3, amtBack1);
		uint amtBack3 = getAmountOutMin(_router3, _token3, _token1, amtBack2);
		return amtBack3;
	}

	function triDexTrade(address _router1, address _router2, address _router3, address _token1, address _token2, address _token3, uint256 _amount) external onlyOwner {
		uint startBalance = IERC20(_token1).balanceOf(address(this));
		uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
		uint token3InitialBalance = IERC20(_token3).balanceOf(address(this));
		swap(_router1,_token1, _token2,_amount);
		uint token2Balance = IERC20(_token2).balanceOf(address(this));
		uint tradeableAmount = token2Balance - token2InitialBalance;
		swap(_router2,_token2, _token3,tradeableAmount);
		uint token3Balance = IERC20(_token3).balanceOf(address(this));
		uint tradeableAmount2 = token3Balance - token3InitialBalance;
		swap(_router3,_token3, _token1,tradeableAmount2);
		uint endBalance = IERC20(_token1).balanceOf(address(this));
		require(endBalance > startBalance, "Trade Reverted, No Profit Made");
	}

	function triDexTradeHold(address _router1, address _router2, address _router3, address _token1, address _token2, address _token3, uint256 _amount) external onlyOwner {
		uint startBalance = IERC20(_token1).balanceOf(address(this));
		uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
		uint token3InitialBalance = IERC20(_token3).balanceOf(address(this));
		swap(_router1,_token1, _token2,_amount);
		uint token2Balance = IERC20(_token2).balanceOf(address(this));
		uint tradeableAmount = token2Balance - token2InitialBalance;
		swap(_router2,_token2, _token3,tradeableAmount);
		uint token3Balance = IERC20(_token3).balanceOf(address(this));
		uint tradeableAmount2 = token3Balance - token3InitialBalance;
		SwapBufferEntry memory entry = SwapBufferEntry(startBalance, _router3,_token3, _token1,tradeableAmount2);
		buffer.push(entry);
		emit SwapBuffered(entry);
	}
    
	function estimateMultiDexLoopTrade(address[] calldata _routerList, address[] calldata _tokenList, uint256 _amount) external view returns (uint256) {
        require(_routerList.length == _tokenList.length, "The number of exchanges must match the number of tokens");
        require(_tokenList.length > 1, "At least two tokens must be specified");
        
        uint i;
        uint nextIndex;
        
		//Estimate each exchange swap hop
		for(i = 0; i < _tokenList.length; i += 1) {
			//We want the index of the last token to be looped back around to the first token
			nextIndex = (i + 1) % _tokenList.length;
            //Get Amount Out Min
			_amount = getAmountOutMin(_routerList[i], _tokenList[i], _tokenList[nextIndex], uint(_amount));
		}
        return _amount;
    }

	function multiDexLoopTrade(address[] calldata _routerList, address[] calldata _tokenList, uint256 _amount) external onlyOwner {
        require(_routerList.length == _tokenList.length, "The number of exchanges must match the number of tokens");
        require(_tokenList.length > 1, "At least two tokens must be specified");
        
		uint tokenArrayLength = _tokenList.length;
        uint[] memory startingBalanceList = new uint[](tokenArrayLength);
        uint[] memory endingBalanceList = new uint[](tokenArrayLength);
		int amount = int(_amount);
        uint i;
        uint nextIndex;

            //Get the starting balance of each token
		for(i = 0; i < tokenArrayLength; i += 1) {
			startingBalanceList[i] = IERC20(_tokenList[i]).balanceOf(address(this));
		}
		
		//Perform each exchange swap
		for(i = 0; i < tokenArrayLength; i += 1) {
			//We want the index of the last token to be looped back around to the first token
			nextIndex = (i + 1) % tokenArrayLength;
			emit StringLog("Index:", int(i));
			emit StringLog("Amount:", amount);
			
			uint amountOut = getAmountOutMin(_routerList[i], _tokenList[i], _tokenList[nextIndex], uint(amount));
			emit UIntLog("amountOut: ", amountOut);
			if (amountOut < 1) {
				emit StringLog("Amount out is less than 1. Route could be bad.", 0);
			} else {
				//Do the actual swap
				bool swapSuccessful = swap(_routerList[i], _tokenList[i], _tokenList[nextIndex], uint(amount));
                //require(swapSuccessful, "The swap failed");
                if (!swapSuccessful) {
                    emit StringLog("The swap failed maaan!", 0);
                }
			}
			
			//Save the balance of the destination token after the swap
			endingBalanceList[nextIndex] = IERC20(_tokenList[nextIndex]).balanceOf(address(this));
            
			emit StringLog("Ending Balance:", int(endingBalanceList[nextIndex]));
			emit StringLog("Starting Balance:", int(startingBalanceList[nextIndex]));
			//The next trade amount will come from the balance difference our swap made
			amount = int(endingBalanceList[nextIndex]) - int(startingBalanceList[nextIndex]);
		}
		emit UIntLog("Uint Ending Balance:", endingBalanceList[0]);
		emit UIntLog("Uint Starting Balance:", startingBalanceList[0]);
		uint endBalance = endingBalanceList[0];
		uint startBalance = startingBalanceList[0];
        //If you end up with less than you started, then back out of the trade
		if (endBalance > startBalance) {
			emit StringLog("Completed trade successfully", 1);
		} else {
			emit StringLog("Trade should be reverted, No Profit Made", 0);

		}
   		require(endBalance > startBalance, "Trade Reverted, No Profit Made");
    }

	function getBalance (address _tokenContractAddress) external view  returns (uint256) {
		uint balance = IERC20(_tokenContractAddress).balanceOf(address(this));
		return balance;
	}
	
	function recoverEth() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function recoverTokens(address tokenAddress) external onlyOwner {
		IERC20 token = IERC20(tokenAddress);
		token.transfer(msg.sender, token.balanceOf(address(this)));
	}

}