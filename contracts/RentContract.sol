// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

contract RentMannagementSystem {

    address public ContractAdmin; //Deploy address

    constructor() {
        ContractAdmin = msg.sender; // Deploy address
    }

    mapping(address => bool) public blackList;

    struct User {
        string Name;
        address UserAddress;
        bool isOwner; //owner 1 / Tenant 0
    }

    struct Property {
        address ownerAddress;
        string propertyAddress;
        string propertyType; //ev veya dükkan
        bool contractValidityStatus;
        uint contractID; //default zero
    }

    struct RentContract {
        address ownerAddress;
        address tenantAddress;
        string propertyAddress;
        string propertyType; //ev veya dükkan
        uint contractStartDate;
        uint contractFinishDate;
        bool validityStatus ;
        bool earlyTerminate;
    }

    struct ContractTerminater {
        uint contractID;
        address userAddress;
        string TerminationReason;
        address willApprove;
    }

    struct ContractComplain {
        uint contractID;
        address userAddress;
        address targetAddress;
        string ComplainReason;
        address willApprove;
    }

    mapping(address => User) public userInformations;
    mapping(string => Property) public propertyInformations;
    mapping(uint => RentContract) public contractInformations;
    mapping(uint => ContractComplain) public contractComplainReasons; //contract id and complains
    mapping(uint => ContractTerminater) public contractTerminateReasons; //contract id and terminate
    

    function createUser(string memory _name, bool _isOwner) public {
        //The user who wants to register is checked from the user list
        require(userInformations[msg.sender].UserAddress == address(0), "User is already registered"); 
        userInformations[msg.sender] = User(_name, msg.sender, _isOwner);
    }

    function addProperty(string memory _propertyAddress, string memory _propertyType) public {
        //The existence of the address to perform the transaction is checked from the user list.
        require(userInformations[msg.sender].UserAddress != address(0), "User not found");
        //Is the user who will make the addition a host?
        require(userInformations[msg.sender].isOwner, "Tenants can't add properties");
        //Is there a landlord address in the list where the property address is registered?
        require(propertyInformations[_propertyAddress].ownerAddress == address(0), "Property already exists");
        propertyInformations[_propertyAddress] = Property(msg.sender, _propertyAddress, _propertyType, false, 0);
    }

    function contractStart(address _tenantAddress, string memory _propertyAddress, string memory _propertyType, uint _contractStartDate, uint _contractFinishDate) public {
        require(userInformations[msg.sender].UserAddress != address(0), "User not found");
        require(userInformations[msg.sender].isOwner, "Tenants cannot initiate a contract");
        require(propertyInformations[_propertyAddress].ownerAddress != address(0), "Property not found");

        uint contractID = uint(keccak256(abi.encodePacked(msg.sender, _propertyAddress, _contractStartDate, _contractFinishDate)));

        contractInformations[contractID] = RentContract(msg.sender, _tenantAddress,  _propertyAddress, _propertyType, _contractStartDate, _contractFinishDate, true, false);
        propertyInformations[_propertyAddress].contractID = contractID;
    }

    function contractTerminate(uint _contractID, bool _legitimate, string memory _reason) public {
        //Contract termination can only be done by the tenant and the landlord
        require(contractInformations[_contractID].tenantAddress == msg.sender || contractInformations[_contractID].ownerAddress == msg.sender, "You have no authority.");
        require(contractInformations[_contractID].validityStatus == true, "Contract is not valid");

        // Tenant can terminate the contract unconditionally
        if (contractInformations[_contractID].tenantAddress == msg.sender) {
                    
            uint finishDate = contractInformations[_contractID].contractFinishDate;
            uint lastFifteenDay = block.timestamp + (15 days); // current time + 15 gün

            require(finishDate < lastFifteenDay, "Not 15 days before the contract end date");
            if(finishDate < lastFifteenDay)
            {
                contractInformations[_contractID].earlyTerminate = true; //termination status true
                contractInformations[_contractID].validityStatus = false; //contract activity has been terminated
            }
            else 
            {
                contractTerminateReasons[_contractID] = ContractTerminater(_contractID, contractInformations[_contractID].tenantAddress , _reason, contractInformations[_contractID].ownerAddress );
            }
     

        }
        
        // The property owner indicates justified/unfair termination
        if (contractInformations[_contractID].ownerAddress == msg.sender) {
            // If the landlord wants to terminate with just cause, he/she waits for approval.
            if (_legitimate) {

                contractTerminateReasons[_contractID] = ContractTerminater(_contractID, contractInformations[_contractID].ownerAddress , _reason, contractInformations[_contractID].tenantAddress );              
                //contractInformations[_contractID].validityStatus = false;
            } else {
                // Ev sahibi haksız fesih yapmak istiyorsa direkt olarak sözleşmeyi sonlandırabilir
                contractTerminateReasons[_contractID] = ContractTerminater(_contractID, contractInformations[_contractID].ownerAddress , _reason, contractInformations[_contractID].tenantAddress );  
                //require(msg.sender == contractInformations[_contractID].tenantAddress , "Only tenant can confirm");
                contractTerminateReasons[_contractID] = ContractTerminater(_contractID, contractInformations[_contractID].ownerAddress , _reason, ContractAdmin );  
                
                //require(msg.sender == ContractAdmin, "Only the person who deployed can confirm");
                //contractInformations[_contractID].earlyTerminate = true;
                //contractInformations[_contractID].validityStatus = false;
            }
        }
    }

    function contractTerminateManage(uint _contractID, bool _approve) public {
        require(contractInformations[_contractID].validityStatus == true, "Contract is not valid");
        require(contractTerminateReasons[_contractID].willApprove == msg.sender, "User not authorized");

        if(_approve == true)
        {
                contractInformations[_contractID].earlyTerminate = true;
                contractInformations[_contractID].validityStatus = false;
        }


    }

    function complainUser(uint _contractID, string memory _complainReason) public {
        require(contractInformations[_contractID].tenantAddress == msg.sender || contractInformations[_contractID].ownerAddress == msg.sender, "Only the tenant or property owner can file a complaint");
        if (contractInformations[_contractID].tenantAddress == msg.sender)
        {

             contractComplainReasons[_contractID] = ContractComplain(_contractID, contractInformations[_contractID].tenantAddress, contractInformations[_contractID].ownerAddress , _complainReason,  ContractAdmin);

        }

        if (contractInformations[_contractID].ownerAddress == msg.sender)
        {

             contractComplainReasons[_contractID] = ContractComplain(_contractID, contractInformations[_contractID].ownerAddress , contractInformations[_contractID].tenantAddress, _complainReason, ContractAdmin );

        }
       

    }

    function complainUserManage(uint _contractID, bool _approve) public {
        require(contractInformations[_contractID].validityStatus == true, "Contract is not valid");
        require(contractComplainReasons[_contractID].willApprove == msg.sender, "User not authorized");

        if(_approve == true)
        {
            blackList[contractComplainReasons[_contractID].targetAddress] = true;
        }


    }

    function getBlackListStatus(address _userAddress) public view returns (bool) {
        return blackList[_userAddress];
    }

    function getComplains(uint _contractID) public view returns (uint ID, address user, address target, string memory reason) {
        return (contractComplainReasons[_contractID].contractID,contractComplainReasons[_contractID].userAddress,contractComplainReasons[_contractID].targetAddress,contractComplainReasons[_contractID].ComplainReason );

    
    }

    function getTerminateRequest(uint _contractID) public view returns (uint ID, address user,  string memory reason) {
        return (contractTerminateReasons[_contractID].contractID,contractTerminateReasons[_contractID].userAddress,contractTerminateReasons[_contractID].TerminationReason );

    
    }

    function getContractId(string memory _propertyAddress) public view returns (uint) {
        return propertyInformations[_propertyAddress].contractID;
    }



}