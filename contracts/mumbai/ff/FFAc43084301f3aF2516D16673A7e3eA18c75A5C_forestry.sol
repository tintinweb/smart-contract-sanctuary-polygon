// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.11;

contract forestry{

      
    struct UnitForestry {
      
        bytes32    KeyId;
        bytes32    WoodKind;
        bytes32 CertificateStatus; // m3
        bytes32    VendorName;
        bytes32    VendorLocation1;
        bytes32 ReceivingReference;
        bytes32 Attribut1;
        bytes32 Attribut2;
        bytes32 Attribut3;
        bytes32 Attribut4;    
        bytes32 Attribut5;
    }


    mapping(bytes32 => UnitForestry  ) public UnitForestrys;


    event LogRegister(bytes32 indexed  KeyId);

    mapping(address=>bool) public Owners;
    address public Owner;
    

    modifier onlyOwner() {
        require(
            Owners[msg.sender]==true,
            "Only owner can call this function."
        );
        _;
    }



    constructor() {
        Owners[msg.sender]=true;
    }

     function isExistUnitForestry(bytes32 KeyId)  public view returns(bool isIndeed) 
    {
       
        return (UnitForestrys[KeyId].KeyId == KeyId);
    }
    
    function AddUnitForestry(UnitForestry calldata uF ) external onlyOwner  {
      
         require(!isExistUnitForestry(uF.KeyId),"Data Already Exist !") ;

        UnitForestrys[uF.KeyId].KeyId=uF.KeyId;
        UnitForestrys[uF.KeyId].WoodKind=uF.WoodKind;
        UnitForestrys[uF.KeyId].CertificateStatus=uF.CertificateStatus;
        UnitForestrys[uF.KeyId].VendorName=uF.VendorName;
        
        UnitForestrys[uF.KeyId].VendorLocation1=uF.VendorLocation1;
        UnitForestrys[uF.KeyId].ReceivingReference=uF.ReceivingReference;
        UnitForestrys[uF.KeyId].Attribut1=uF.Attribut1;
        UnitForestrys[uF.KeyId].Attribut2=uF.Attribut2;
      
        
        UnitForestrys[uF.KeyId].Attribut3=uF.Attribut3;
        UnitForestrys[uF.KeyId].Attribut4=uF.Attribut4;
        UnitForestrys[uF.KeyId].Attribut5=uF.Attribut5;
          
        emit LogRegister(uF.KeyId);
      

    }

  
   
   
}