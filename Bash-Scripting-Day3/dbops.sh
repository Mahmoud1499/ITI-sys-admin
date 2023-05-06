source checker.sh

##Function check if id exists or no
##Exit codes:
#	0: Success
#	1: not enough parameter
#	2: Not an integer
#	3: id exists

function checkID {
	[ ${#} -ne 1 ] && return 1
	checkInt ${1}
	[ ${?} -ne 0 ] && return 2
	RES=$(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "select id from ${MYSQLDB}.inv where (id=${1})")
	[ ! -z "${RES}" ] && return 3
	return 0
}

function authenticate {
	echo "Authentication.."
	CURUSER=""
	echo -n "Enter your username: "
	read USERNAME
	echo -n "Enter your password: "
	read -s PASSWORD
	### Start authentication. Query database for the username/password
	RES=$(sudomysql -u ${MYSQLUSER} -p${MYSQLPASS} -e "select username from ${MYSQLDB}.users where (username='${USERNAME}') and (password=md5('${PASSWORD}'))")
	if [ -z "${RES}" ]; then
		echo "Invalid credentials"
		return 1
	else
		CURUSER=${USERNAME}
		echo "Welcome ${CURUSER}"
	fi
	return 0
}

##Function, query a inv
##Exit
#	0: Success
#	1: Not authenticated
#	2: invalid id as an integer
#	3: id not exists
function queryinv {
	echo "Query"
	if [ -z ${CURUSER} ]; then
		echo "Authenticate first"
		return 1
	fi
	echo -n "Enter invoice  id : "
	read ID
	checkInt ${ID}
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 2
	##Check if the ID is already exists or no
	checkID ${ID}
	[ ${?} -eq 0 ] && echo "ID ${ID} not exists!" && return 3
	## We used -s to disable table format
	RES=$(sudo mysql -u ${MYSQLUSER} -p${MYSQLPASS} -s -e "select * from ${MYSQLDB}.inv  where (id=${ID})" | tail -1)
	ID=${ID}
	CUSTOMERNAME=$(echo "${RES}" | awk ' { print $2 } ')
	DATE=$(echo "${RES}" | awk ' {  print $3 } ')
	echo "Invoice ID: ${INVID}"
	echo "Invoice date : ${DATE}"
	echo "Customer name : ${CUSTOMERNAME}"

	echo "Details:"
	echo "Product ID     Quantity      Unit Price     Total Product"
	echo "--------------------------------------------------------"
	mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "select * from ${MYSQLDB}.intdet where (id=${ID})" | while read line; do
		IFS=":" read -r prodid quantity price <<<"${line}"
		TOTAL=$((${quantity} * ${price}))
		echo "${prodid}         ${quantity}         ${price}         ${TOTAL}"
	done

	return 0
}

##Exit codes
#	0: Success
#	1: ID is not an integer
#	2: Total is not an integer
#	3: ID already exists
function insertinv {
	local OPT
	echo "Insert"
	echo "Query"
	if [ -z ${CURUSER} ]; then
		echo "Authenticate first"
		return 1
	fi
	echo -n "Enter inv id : "
	read CUSTID
	checkInt ${CUSTID}
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 1
	##Check if the ID is already exists or no
	checkID ${CUSTID}
	[ ${?} -ne 0 ] && echo "ID ${CUSTID} is already exists!!" && return 3
	echo -n "Enter inv name : "
	read CUSTNAME
	echo -n "Enter invoice total : "
	read INVTOTAL
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 2
	echo -n "Save (y/n)"
	read OPT
	case "${OPT}" in
	"y")
		mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "insert into ${MYSQLDB}.inv (id,total,inv_name) values (${CUSTID},${INVTOTAL},'${CUSTNAME}')"
		echo "Done .."
		;;
	"n")
		echo "Discarded."
		;;
	*)
		echo "Invalid option"
		;;
	esac
	return 0
}

function deleteinv {
	echo "Delete"
	local OPT
	if [ -z ${CURUSER} ]; then
		echo "Authenticate first"
		return 1
	fi
	echo -n "Enter inv id : "
	read CUSTID
	checkInt ${CUSTID}
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 2
	##Check if the ID is already exists or no
	checkID ${CUSTID}
	[ ${?} -eq 0 ] && echo "ID ${CUSTID} not exists!" && return 3
	## We used -s to disable table format
	RES=$(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -s -e "select * from ${MYSQLDB}.inv where (id=${CUSTID})" | tail -1)
	ID=${CUSTID}
	NAME=$(echo "${RES}" | awk ' { print $3 } ')
	TOTAL=$(echo "${RES}" | awk ' {  print $2 } ')
	echo "Details of invoice id ${CUSTID}"
	echo "inv name : ${NAME}"
	echo "Invoice toal : ${TOTAL}"
	echo -n "Delete (y/n)"
	read OPT
	case "${OPT}" in
	"y")
		mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "delete from ${MYSQLDB}.inv where id=${CUSTID}"
		echo "Done .."
		;;
	"n")
		echo "not deleted."
		;;
	*)
		echo "Invalid option"
		;;
	esac

	return 0
}

function updateinv {
	echo "Updating an existing inv"
	echo "Query"
	if [ -z ${CURUSER} ]; then
		echo "Authenticate first"
		return 1
	fi
	return 0
}
function readinvsData {
	echo "Inserting data into database to table invdata"

	# Get the name of the database and table from the environment variables
	DBNAME=$MYSQLDB
	TABLENAME="invdata"

	# Loop through each line in the file and insert it into the table
	while read -r LINE; do
		# Extract the values from the line and construct the insert statement
		ID=$(echo ${LINE} | cut -d ":" -f 1)
		invNAME=$(echo ${LINE} | cut -d ":" -f 2)
		DATE=$(echo ${LINE} | cut -d ":" -f 3)

		#Execute the insert statement using mysql connection
		RES=$(
			sud mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "insert into inv (id, invname, date) 
																			values ('${ID}', '${invNAME}', '${DATE}')"
		)
		if [ -z "${RES}" ]; then
			echo "Error can't get data"
			return 1
		else
			Print a success message for each record inserted

			echo "Record inserted successfully: ${LINE}"
		fi
	done <invdata
}

function readProductsData {
	echo "Extracting data from file and inserting into database table intdet"

	# Get the name of the database and table from the environment variables
	DBNAME=$MYSQLDB
	TABLENAME="intdet"

	# Loop through each line in the file and insert it into the table
	while read -r LINE; do
		# Extract the values from the line and construct the insert statement
		ID=$(echo ${LINE} | cut -d ":" -f 1)
		SERIAL=$(echo ${LINE} | cut -d ":" -f 2)
		PRODID=$(echo ${LINE} | cut -d ":" -f 3)
		QUANTITY=$(echo ${LINE} | cut -d ":" -f 4)
		UNITPRICE=$(echo ${LINE} | cut -d ":" -f 5)
		INSERTSTMT="INSERT INTO ${DBNAME}.${TABLENAME} (id, serial, prodid, quantity, unitprice) 
					VALUES (${ID}, ${SERIAL}, ${PRODID}, ${QUANTITY}, ${UNITPRICE})"

		# Execute the insert statement using mysql connection
		echo "${INSERTSTMT}" | sudo mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} ${DBNAME}

		# Print a success message for each record inserted
		echo "Record inserted successfully: ${LINE}"
	done <'invdet'
}
