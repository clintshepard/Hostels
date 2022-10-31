pragma solidity ^0.5.16;

contract Hostel {
    address payable tenant;
    address payable landlord;
    uint256 public no_of_rooms = 0;
    uint256 public no_of_agreement = 0;
    uint256 public no_of_rent = 0;
    struct Room {
        uint256 roomid;
        uint256 agreementid;
        string roomname;
        string roomaddress;
        uint256 rent_per_month;
        uint256 securityDeposit;
        uint256 timestamp;
        bool vacant;
        address payable landlord;
        address payable currentTenant;
    }
    mapping(uint256 => Room) public Room_by_No;
    struct RoomAgreement {
        uint256 roomid;
        uint256 agreementid;
        string Roomname;
        string RoomAddresss;
        uint256 rent_per_month;
        uint256 securityDeposit;
        uint256 lockInPeriod;
        uint256 timestamp;
        address payable tenantAddress;
        address payable landlordAddress;
    }
    mapping(uint256 => RoomAgreement) public RoomAgreement_by_No;
    struct Rent {
        uint256 rentno;
        uint256 roomid;
        uint256 agreementid;
        string Roomname;
        string RoomAddresss;
        uint256 rent_per_month;
        uint256 timestamp;
        address payable tenantAddress;
        address payable landlordAddress;
    }
    mapping(uint256 => Rent) public Rent_by_No;
    modifier onlyLandlord(uint256 _index) {
        require(
            msg.sender == Room_by_No[_index].landlord,
            "Только землевладелец может получить доступ к этому"
        );
        _;
    }
    modifier notLandLord(uint256 _index) {
        require(
            msg.sender != Room_by_No[_index].landlord,
            "Только жилец может получить доступ к этому"
        );
        _;
    }
    modifier OnlyWhileVacant(uint256 _index) {
        require(
            Room_by_No[_index].vacant == true,
            "Комната уже занята"
        );
        _;
    }
    modifier enoughRent(uint256 _index) {
        require(
            msg.value >= uint256(Room_by_No[_index].rent_per_month),
            "В кошельке недостаточно эфира"
        );
        _;
    }
    modifier enoughAgreementfee(uint256 _index) {
        require(
            msg.value >=
                uint256(
                    uint256(Room_by_No[_index].rent_per_month) +
                        uint256(Room_by_No[_index].securityDeposit)
                ),
            "Недостаточно эфира в кошельке"
        );
        _;
    }
    modifier sameTenant(uint256 _index) {
        require(
            msg.sender == Room_by_No[_index].currentTenant,
            "Не найдено предыдущего договора"
        );
        _;
    }
    modifier AgreementTimesLeft(uint256 _index) {
        uint256 _AgreementNo = Room_by_No[_index].agreementid;
        uint256 time = RoomAgreement_by_No[_AgreementNo].timestamp +
            RoomAgreement_by_No[_AgreementNo].lockInPeriod;
        require(now < time, "Договор уже закончился");
        _;
    }
    modifier AgreementTimesUp(uint256 _index) {
        uint256 _AgreementNo = Room_by_No[_index].agreementid;
        uint256 time = RoomAgreement_by_No[_AgreementNo].timestamp +
            RoomAgreement_by_No[_AgreementNo].lockInPeriod;
        require(now > time, "Время кончилось для заключения договора");
        _;
    }
    modifier RentTimesUp(uint256 _index) {
        uint256 time = Room_by_No[_index].timestamp + 30 days;
        require(now >= time, "Вышла время платить ренту");
        _;
    }

    function addRoom(
        string memory _roomname,
        string memory _roomaddress,
        uint256 _rentcost,
        uint256 _securitydeposit
    ) public {
        require(msg.sender != address(0));
        no_of_rooms++;
        bool _vacancy = true;
        Room_by_No[no_of_rooms] = Room(
            no_of_rooms,
            0,
            _roomname,
            _roomaddress,
            _rentcost,
            _securitydeposit,
            0,
            _vacancy,
            msg.sender,
            address(0)
        );
    }

    function signAgreement(uint256 _index)
        public
        payable
        notLandLord(_index)
        enoughAgreementfee(_index)
        OnlyWhileVacant(_index)
    {
        require(msg.sender != address(0));
        address payable _landlord = Room_by_No[_index].landlord;
        uint256 totalfee = Room_by_No[_index].rent_per_month +
            Room_by_No[_index].securityDeposit;
        _landlord.transfer(totalfee);
        no_of_agreement++;
        Room_by_No[_index].currentTenant = msg.sender;
        Room_by_No[_index].vacant = false;
        Room_by_No[_index].timestamp = block.timestamp;
        Room_by_No[_index].agreementid = no_of_agreement;
        RoomAgreement_by_No[no_of_agreement] = RoomAgreement(
            _index,
            no_of_agreement,
            Room_by_No[_index].roomname,
            Room_by_No[_index].roomaddress,
            Room_by_No[_index].rent_per_month,
            Room_by_No[_index].securityDeposit,
            365 days,
            block.timestamp,
            msg.sender,
            _landlord
        );
        no_of_rent++;
        Rent_by_No[no_of_rent] = Rent(
            no_of_rent,
            _index,
            no_of_agreement,
            Room_by_No[_index].roomname,
            Room_by_No[_index].roomaddress,
            Room_by_No[_index].rent_per_month,
            now,
            msg.sender,
            _landlord
        );
    }

    function payRent(uint256 _index)
        public
        payable
        sameTenant(_index)
        RentTimesUp(_index)
        enoughRent(_index)
    {
        require(msg.sender != address(0));
        address payable _landlord = Room_by_No[_index].landlord;
        uint256 _rent = Room_by_No[_index].rent_per_month;
        _landlord.transfer(_rent);
        Room_by_No[_index].currentTenant = msg.sender;
        Room_by_No[_index].vacant = false;
        no_of_rent++;
        Rent_by_No[no_of_rent] = Rent(
            no_of_rent,
            _index,
            Room_by_No[_index].agreementid,
            Room_by_No[_index].roomname,
            Room_by_No[_index].roomaddress,
            _rent,
            now,
            msg.sender,
            Room_by_No[_index].landlord
        );
    }

    function agreementCompleted(uint256 _index)
        public
        payable
        onlyLandlord(_index)
        AgreementTimesUp(_index)
    {
        require(msg.sender != address(0));
        require(
            Room_by_No[_index].vacant == false,
            "Комната уже занята"
        );
        Room_by_No[_index].vacant = true;
        address payable _Tenant = Room_by_No[_index].currentTenant;
        uint256 _securitydeposit = Room_by_No[_index].securityDeposit;
        _Tenant.transfer(_securitydeposit);
    }

    function agreementTerminated(uint256 _index)
        public
        onlyLandlord(_index)
        AgreementTimesLeft(_index)
    {
        require(msg.sender != address(0));
        Room_by_No[_index].vacant = true;
    }
}
