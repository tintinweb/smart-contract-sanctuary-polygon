/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

// File: newFile_test_flat_flat.sol


// File: newFile_test_flat.sol


// File: remix_accounts.sol



pragma solidity >=0.4.22 <0.9.0;

library TestsAccounts {
    function getAccount(uint index) pure public returns (address) {
        address[15] memory accounts;
		accounts[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

		accounts[1] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

		accounts[2] = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;

		accounts[3] = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;

		accounts[4] = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;

		accounts[5] = 0x17F6AD8Ef982297579C203069C1DbfFE4348c372;

		accounts[6] = 0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678;

		accounts[7] = 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7;

		accounts[8] = 0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C;

		accounts[9] = 0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC;

		accounts[10] = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;

		accounts[11] = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;

		accounts[12] = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;

		accounts[13] = 0x583031D1113aD414F02576BD6afaBfb302140225;

		accounts[14] = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;

        return accounts[index];
    }
}

// File: remix_tests.sol



pragma solidity >=0.4.22 <0.9.0;

library Assert {

  event AssertionEvent(
    bool passed,
    string message,
    string methodName
  );

  event AssertionEventUint(
    bool passed,
    string message,
    string methodName,
    uint256 returned,
    uint256 expected
  );

  event AssertionEventInt(
    bool passed,
    string message,
    string methodName,
    int256 returned,
    int256 expected
  );

  event AssertionEventBool(
    bool passed,
    string message,
    string methodName,
    bool returned,
    bool expected
  );

  event AssertionEventAddress(
    bool passed,
    string message,
    string methodName,
    address returned,
    address expected
  );

  event AssertionEventBytes32(
    bool passed,
    string message,
    string methodName,
    bytes32 returned,
    bytes32 expected
  );

  event AssertionEventString(
    bool passed,
    string message,
    string methodName,
    string returned,
    string expected
  );

  event AssertionEventUintInt(
    bool passed,
    string message,
    string methodName,
    uint256 returned,
    int256 expected
  );

  event AssertionEventIntUint(
    bool passed,
    string message,
    string methodName,
    int256 returned,
    uint256 expected
  );

  function ok(bool a, string memory message) public returns (bool result) {
    result = a;
    emit AssertionEvent(result, message, "ok");
  }

  function equal(uint256 a, uint256 b, string memory message) public returns (bool result) {
    result = (a == b);
    emit AssertionEventUint(result, message, "equal", a, b);
  }

  function equal(int256 a, int256 b, string memory message) public returns (bool result) {
    result = (a == b);
    emit AssertionEventInt(result, message, "equal", a, b);
  }

  function equal(bool a, bool b, string memory message) public returns (bool result) {
    result = (a == b);
    emit AssertionEventBool(result, message, "equal", a, b);
  }

  // TODO: only for certain versions of solc
  //function equal(fixed a, fixed b, string message) public returns (bool result) {
  //  result = (a == b);
  //  emit AssertionEvent(result, message);
  //}

  // TODO: only for certain versions of solc
  //function equal(ufixed a, ufixed b, string message) public returns (bool result) {
  //  result = (a == b);
  //  emit AssertionEvent(result, message);
  //}

  function equal(address a, address b, string memory message) public returns (bool result) {
    result = (a == b);
    emit AssertionEventAddress(result, message, "equal", a, b);
  }

  function equal(bytes32 a, bytes32 b, string memory message) public returns (bool result) {
    result = (a == b);
    emit AssertionEventBytes32(result, message, "equal", a, b);
  }

  function equal(string memory a, string memory b, string memory message) public returns (bool result) {
     result = (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
     emit AssertionEventString(result, message, "equal", a, b);
  }

  function notEqual(uint256 a, uint256 b, string memory message) public returns (bool result) {
    result = (a != b);
    emit AssertionEventUint(result, message, "notEqual", a, b);
  }

  function notEqual(int256 a, int256 b, string memory message) public returns (bool result) {
    result = (a != b);
    emit AssertionEventInt(result, message, "notEqual", a, b);
  }

  function notEqual(bool a, bool b, string memory message) public returns (bool result) {
    result = (a != b);
    emit AssertionEventBool(result, message, "notEqual", a, b);
  }

  // TODO: only for certain versions of solc
  //function notEqual(fixed a, fixed b, string message) public returns (bool result) {
  //  result = (a != b);
  //  emit AssertionEvent(result, message);
  //}

  // TODO: only for certain versions of solc
  //function notEqual(ufixed a, ufixed b, string message) public returns (bool result) {
  //  result = (a != b);
  //  emit AssertionEvent(result, message);
  //}

  function notEqual(address a, address b, string memory message) public returns (bool result) {
    result = (a != b);
    emit AssertionEventAddress(result, message, "notEqual", a, b);
  }

  function notEqual(bytes32 a, bytes32 b, string memory message) public returns (bool result) {
    result = (a != b);
    emit AssertionEventBytes32(result, message, "notEqual", a, b);
  }

  function notEqual(string memory a, string memory b, string memory message) public returns (bool result) {
    result = (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b)));
    emit AssertionEventString(result, message, "notEqual", a, b);
  }

  /*----------------- Greater than --------------------*/
  function greaterThan(uint256 a, uint256 b, string memory message) public returns (bool result) {
    result = (a > b);
    emit AssertionEventUint(result, message, "greaterThan", a, b);
  }

  function greaterThan(int256 a, int256 b, string memory message) public returns (bool result) {
    result = (a > b);
    emit AssertionEventInt(result, message, "greaterThan", a, b);
  }
  // TODO: safely compare between uint and int
  function greaterThan(uint256 a, int256 b, string memory message) public returns (bool result) {
    if(b < int(0)) {
      // int is negative uint "a" always greater
      result = true;
    } else {
      result = (a > uint(b));
    }
    emit AssertionEventUintInt(result, message, "greaterThan", a, b);
  }
  function greaterThan(int256 a, uint256 b, string memory message) public returns (bool result) {
    if(a < int(0)) {
      // int is negative uint "b" always greater
      result = false;
    } else {
      result = (uint(a) > b);
    }
    emit AssertionEventIntUint(result, message, "greaterThan", a, b);
  }
  /*----------------- Lesser than --------------------*/
  function lesserThan(uint256 a, uint256 b, string memory message) public returns (bool result) {
    result = (a < b);
    emit AssertionEventUint(result, message, "lesserThan", a, b);
  }

  function lesserThan(int256 a, int256 b, string memory message) public returns (bool result) {
    result = (a < b);
    emit AssertionEventInt(result, message, "lesserThan", a, b);
  }
  // TODO: safely compare between uint and int
  function lesserThan(uint256 a, int256 b, string memory message) public returns (bool result) {
    if(b < int(0)) {
      // int is negative int "b" always lesser
      result = false;
    } else {
      result = (a < uint(b));
    }
    emit AssertionEventUintInt(result, message, "lesserThan", a, b);
  }

  function lesserThan(int256 a, uint256 b, string memory message) public returns (bool result) {
    if(a < int(0)) {
      // int is negative int "a" always lesser
      result = true;
    } else {
      result = (uint(a) < b);
    }
    emit AssertionEventIntUint(result, message, "lesserThan", a, b);
  }
}

// File: as/newFile_test.sol


        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix


// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin

// <import file to test>

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // <instantiate contract>
        Assert.equal(uint(1), uint(1), "1 should be equal to 1");
    }

    function checkSuccess() public {
        // Use 'Assert' methods: https://remix-ide.readthedocs.io/en/latest/assert_library.html
        Assert.ok(2 == 2, 'should be true');
        Assert.greaterThan(uint(2), uint(1), "2 should be greater than to 1");
        Assert.lesserThan(uint(2), uint(3), "2 should be lesser than to 3");
    }

    function checkSuccess2() public pure returns (bool) {
        // Use the return value (true or false) to test the contract
        return true;
    }
    
    function checkFailure() public {
        Assert.notEqual(uint(1), uint(1), "1 should not be equal to 1");
    }

    /// Custom Transaction Context: https://remix-ide.readthedocs.io/en/latest/unittesting.html#customization
    /// #sender: account-1
    /// #value: 100
    function checkSenderAndValue() public payable {
        // account index varies 0-9, value is in wei
        Assert.equal(msg.sender, TestsAccounts.getAccount(1), "Invalid sender");
        Assert.equal(msg.value, 100, "Invalid value");
    }
}