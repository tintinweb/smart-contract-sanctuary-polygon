// SPDX-License-Identifier: MIT

contract Notes {
	mapping(uint256 => mapping(string => string)) private _notes;
	mapping(address => uint256[]) private _usrIds;
	uint256 public storedData = 0;

	event StoreData(address indexed from, uint256 id);

	function Save(string memory _secret, string memory _note) public {
		uint256 id = generateId(generateKey(generateKey(_note)));
		_notes[id][_secret] = _note;

		storedData += 1;
		_usrIds[msg.sender].push(id);

		emit StoreData(msg.sender, id);
	}

	function noteList(address user) public view virtual returns (uint256[] memory) {
		return _usrIds[user];
	}

	function generateId(string memory seed) internal pure returns (uint256) {
		bytes32 b = keccak256(abi.encodePacked(seed));
		uint256 number;
		for (uint i = 0; i < b.length; i++) {
			number = number + uint(uint8(b[i]))*(2**(8*(b.length - (i+1))));
		}
		return number;
	}

	function retrive(uint256 _id, string memory _secret) public view virtual returns(string memory) {
		return _notes[_id][_secret];
	}

	function generateKey(string memory seed) internal pure returns (string memory) {
		bytes32 _bytes32 = keccak256(abi.encodePacked(seed));
		uint8 i = 0;
		while(i < 32 && _bytes32[i] != 0) {
				i++;
		}
		bytes memory bytesArray = new bytes(i);
		for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
				bytesArray[i] = _bytes32[i];
		}
		return string(bytesArray);
  }
}