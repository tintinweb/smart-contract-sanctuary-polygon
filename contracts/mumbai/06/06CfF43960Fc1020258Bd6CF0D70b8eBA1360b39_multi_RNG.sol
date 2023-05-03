/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

// By jnbez 
//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract multi_RNG {

     // A constant value used for the modulo operation later in the contract
    uint256 constant P = 0xE96C6372AB55884E99242C8341393C43953A3C8C6F6D57B3B863C882DEFFC3B7;
    
    // The address of the owner (set during contract deployment)
    address public owner;
    
    // Event emitted when encryption is initiated
    event EncryptionInitiated(uint256 indexed _id, address[] _parties, uint256 _z, uint256 _d,uint256 _Encryption);
    
    // Event emitted when encryption is accepted by a party
    event EncryptionAccepted(uint256 indexed _id, address _accepter, uint256 _Encryption);
    
    // Event emitted when a coefficient and random number are revealed by a party
    event Revealed(uint256 indexed _id, address indexed _from, uint256 _coeff, uint256 _rng);
    
    // Event emitted when a process has been completed and a result produced
    event Done(uint256 indexed _id, uint256 _result);
    
    // Modifier to ensure that only the owner of the contract can call Withdraw functions
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // Struct containing data relating to the process
    struct ProcessData {
        uint256 id; // ID of the process
        bool initiated; // Boolean indicating whether or not the process has been initiated
        address[] addresses; // Array of addresses (including sender , initializer of process) involved in the process
        mapping(address => uint256) user_encryption; // Mapping of each address to their assigned encryption value
        uint256 z; // Lower bound of the range for the result
        uint256 d; // Upper bound of the range for the result
        uint256 res; // Result produced by the process
        mapping(address => uint) user_Accepted; // Mapping of each address to whether or not they have accepted the encryption
        mapping(address=>uint) user_signed; // Mapping of each address to whether or not they have signed the process
    }
    
    // Struct containing data relating to a signature
    struct Sig {
        string message; // Message signed by the party (contains the number being agreed upon)
        uint8 v; // Recovery identifier (part of the signature)
        bytes32 r; // First 32 bytes of the signature
        bytes32 s; // Second 32 bytes of the signature
    }
    
    // Mapping of process IDs to their associated data
    mapping(uint256 => ProcessData) processes;
    
    // Constructor function - sets the owner of the contract to be the sender of the transaction
    constructor() {
        owner = msg.sender;
    }

    // UTILS :

    function stringToUint(string memory _s)internal pure returns (uint256 result)
    {
        bytes memory a = bytes(_s);
        uint256 i;
        result = 0;
        for (i = 0; i < a.length; i++) {
            uint8 b = uint8(a[i]);
            if (b >= 48 && b <= 57) {
                result = result * 10 + (b - 48);
            }
        }
    }

    function substring(string memory _str, uint256 _start_Index) internal pure returns (string memory)
    {
        bytes memory strBytes = bytes(_str);
        uint256 endIndex = strBytes.length;
        bytes memory result = new bytes(endIndex - _start_Index);
        for (uint256 i = _start_Index; i < endIndex; i++) {
            result[i - _start_Index] = strBytes[i];
        }
        return string(result);
    }



 function calculate_messages(Sig[] memory _sigs) internal pure returns (uint256) {
        require(_sigs.length > 1, "Expected at least two messages");

        uint256 num = 0;
        bool initialized = false;

        for (uint i = 0; i < _sigs.length; i++) {
            string memory message = _sigs[i].message;
            string memory num_str = substring(message, 14);
            uint256 curr_num = stringToUint(num_str);

            if (!initialized) {
                num = curr_num;
                initialized = true;
            } else {
                require(curr_num == num, "Message does not match");
            }
        }

        return num;
    }

    function calculate_result(uint256[] memory _numbers, uint256 _id) internal view returns (uint256) {
        uint256 sum;
        for (uint i = 0; i < _numbers.length; i++) {
            sum += _numbers[i];
        }
        return (((sum % P) % (processes[_id].d - processes[_id].z)) + processes[_id].z);
    }
    




    // Function to extract a signer's address from an ECDSA signature

  function ExtractAddress(string memory _message,uint8 _v,bytes32 _r,bytes32 _s) public pure returns (address _signer) {


        uint256 lengthOffset;
        uint256 length;
        string memory _header = "\x19Ethereum Signed Message:\n000000";

        assembly {
            // The first word of a string is its length
            length := mload(_message)
            // The beginning of the base-10 message length in the prefix
            lengthOffset := add(_header, 57)
        }

        // Maximum length we support
        require(length <= 999999);
        // The length of the message's length in base-10
        uint256 lengthLength = 0;
        // The divisor to get the next left-most message length digit
        uint256 divisor = 100000;
        // Move one digit of the message length to the right at a time
        while (divisor != 0) {
            // The place value at the divisor
            uint256 digit = length / divisor;
            if (digit == 0) {
                // Skip leading zeros
                if (lengthLength == 0) {divisor /= 10;continue;}}
            // Found a non-zero digit or non-leading zero digit
            lengthLength++;
            // Remove this digit from the message length's current value
            length -= digit * divisor;
            // Shift our base-10 divisor over
            divisor /= 10;
            // Convert the digit to its ASCII representation (man ascii)
            digit += 0x30;
            // Move to the next character and write the digit
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        // The null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        // Truncate the tailing zeros from the header
        assembly {
            mstore(_header, lengthLength)
        }
        // Perform the elliptic curve recover operation
        bytes32 check = keccak256(abi.encodePacked(_header, _message));
        return ecrecover(check, _v, _r, _s);
    }


    // Logic :

   function InitiateEncryption(uint256 _id, address[] memory _parties, uint256 _e, uint256 _z, uint256 _d) public {
    require(!processes[_id].initiated,"Already initiated");

    // Initialize the `addresses` array with a length equal to the number of parties + 1 (for the sender)
    processes[_id].addresses = new address[](_parties.length + 1);
    
    // set the first address in the array as the sender
    processes[_id].addresses[0] = msg.sender;
    
    // set the remaining addresses in the array as other parties
    for(uint i=0; i<_parties.length; i++){
        processes[_id].addresses[i+1] = _parties[i];
    }

    processes[_id].id = _id;
    processes[_id].initiated = true;
    processes[_id].z = _z;
    processes[_id].d = _d;
    processes[_id].user_encryption[msg.sender] = _e;
    processes[_id].user_Accepted[msg.sender]=1;

    emit EncryptionInitiated(_id, processes[_id].addresses, _z, _d, _e);
}



    function AcceptEncryption(uint256 id, uint256 e) public {
      require(processes[id].user_Accepted[msg.sender]==0,"Already Accepted");
      require(processes[id].initiated);
     
     bool isAuthorized = false;
    for (uint i = 0; i < processes[id].addresses.length; i++) {
        if (msg.sender == processes[id].addresses[i]) {
            isAuthorized = true;
            break;
        }
    }
    require(isAuthorized,"Not Authorized");
    processes[id].user_Accepted[msg.sender]=1;

        processes[id].user_encryption[msg.sender] = e;
        emit EncryptionAccepted(id, msg.sender, e);
    }




    function Finish_Procces(uint256 id,uint256[] calldata coeff,uint256[] calldata rng,Sig[] memory _sigs) public {
        require(processes[id].initiated);
        require(msg.sender != processes[id].addresses[0],"Faild,initializer can't finish");
        require(processes[id].user_Accepted[msg.sender]==1,"Accpet encryption First");
        
        uint agree =0 ;

      
        for (uint i = 0; i < _sigs.length; i++) {

        address signer =  ExtractAddress(_sigs[i].message, _sigs[i].v, _sigs[i].r, _sigs[i].s);
        require(signer == processes[id].addresses[i],"Invalid signature,Not Authorized"  );

        require(processes[id].user_signed[signer]==0,"duplicate signature");
                processes[id].user_signed[signer]=1;
                if(processes[id].user_Accepted[signer]==1)
                {
                    agree = agree+1;
                    }
                                                    }
//51% of parties have to accept encryption to finsh process 
    require(agree > _sigs.length/2, "Half of parties don't accept");

        uint256 num_1 = calculate_messages(_sigs);

        processes[id].res = calculate_result(rng, id);
        require(num_1 == processes[id].res,"Cheating,invalid number");


            for (uint i = 0; i < coeff.length; i++) {
            emit Revealed(id, processes[id].addresses[i], coeff[i], rng[i]);
        }


        emit Done(id, processes[id].res);
    }




    function withdraw(uint _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");
        (bool success, ) = payable(owner).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    receive() external payable {}

    fallback() external payable {}
}