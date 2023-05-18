/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SolidityLogTest { 

	event Fire();
	function test1(string memory n) external { 
		emit Fire();
		bytes32 e = keccak256(abi.encodePacked(n)); 
		assembly {   
			log1(0x0, 0x0, e)    
		}
	}

	event Fire(int256 indexed t1);
	function test2(string memory n, int256 t1) external {  
		emit Fire(t1);
		bytes32 e = keccak256(abi.encodePacked(n)); 
		assembly {   
			log2(0x0, 0x0, e, t1)    
		}
	}

	event Fire(uint256 indexed t1);
	function test3(string memory n, uint256 t1) external {
		emit Fire(t1);
		bytes32 e = keccak256(abi.encodePacked(n)); 
		assembly {   
			log2(0x0, 0x0, e, t1)    
		}
	}

	event Fire(string indexed t1);
	function test4(string memory n, string memory t1) external {
		emit Fire(t1);
		bytes32 e = keccak256(abi.encodePacked(n)); 
		bytes32 t1_ = keccak256(abi.encodePacked(t1)); 
		assembly {   
			log2(0x0, 0x0, e, t1_)    
		}
	}

	event Fire(bool indexed t1);
	function test5(string memory n, bool t1) external {
		emit Fire(t1);
		bytes32 e = keccak256(abi.encodePacked(n));  
		assembly {   
			log2(0x0, 0x0, e, t1)    
		}
	}

	event Fire(address indexed t1);
	function test6(string memory n, address t1) external {
		emit Fire(t1);
		bytes32 e = keccak256(abi.encodePacked(n));  
		assembly {   
			log2(0x0, 0x0, e, t1)    
		}
	}

	event Fire(bytes32 indexed t1);
	function test7(string memory n, bytes32 t1) external {
		emit Fire(t1);
		bytes32 e = keccak256(abi.encodePacked(n));  
		assembly {   
			log2(0x0, 0x0, e, t1)    
		}
	} 

	event Fire(address indexed t1, uint256 indexed t2);
	function test8(string memory n, address t1, uint256 t2) external { 
		emit Fire(t1, t2);
		bytes32 e = keccak256(abi.encodePacked(n));  
		assembly {   
			log3(0x0, 0x0, e, t1, t2)    
		}
	}

	event Fire(address indexed t1, uint256 indexed t2, bool indexed t3);
	function test9(string memory n, address t1, uint256 t2, bool t3) external { 
		emit Fire(t1, t2, t3);
		bytes32 e = keccak256(abi.encodePacked(n));  
		assembly {   
			log4(0x0, 0x0, e, t1, t2, t3)    
		}
	} 

	event Fire(address indexed t1, uint256 indexed t2, bool indexed t3, int128 abc);
	function test10(string memory n, address t1, uint256 t2, bool t3, int128 abc) external { 
		emit Fire(t1, t2, t3, abc);
		bytes32 e = keccak256(abi.encodePacked(n));   
		assembly {   
			let p := add(0x0, 0x20)
			mstore(p, abc) 
			log4(p, 0x20, e, t1, t2, t3)    
		}
	}  
	

	/***** General Log for testing *****/
	event Fire(address indexed t1, uint256 indexed t2, bool indexed t3, uint256 age);
	event Fire(address indexed t1, uint256 indexed t2, bool indexed t3, string abc);
	event Fire(address indexed t1, uint256 indexed t2, bool indexed t3, string a, uint256 b, bytes32 c); 
	function test11(string memory n, address t1, uint256 t2, bool t3, bytes memory data) external { 
		bytes32 e = keccak256(abi.encodePacked(n));   
		assembly {   
			let p := add(data, 0x20)
			let s := mload(data) 
			log4(p, s, e, t1, t2, t3)    
		}
	} 
	
	function getName(string memory eventName) public pure returns (bytes32) {
		return keccak256(abi.encodePacked(eventName));
	}

}