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
	
	# get data from user
	echo -n "Enter your username: "
	read USERNAME
	echo -n "Enter your password: "
	read -s PASSWORD
	
	### Start authentication. Query database for the username/password
	RES=$(sudomysql -u ${MYSQLUSER} -p${MYSQLPASS} -e "select username from ${MYSQLDB}.users where (username='${USERNAME}') and (password=md5('${PASSWORD}'))")
	
	# check if user exist in databse
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
	
	# check if user is auth
	if [ -z ${CURUSER} ]; then
		echo "Authenticate first"
		return 1
	fi
	# get id from user
	echo -n "Enter invoice  id : "
	read ID
	
	# validate user id is integer 
	checkInt ${ID}
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 2
	
	##Check if the ID is already exists or no
	checkID ${ID}
	[ ${?} -eq 0 ] && echo "ID ${ID} not exists!" && return 3
	
	## We used -s to disable table format
	RES=$(sudo mysql -u ${MYSQLUSER} -p${MYSQLPASS} -s -e "select * from ${MYSQLDB}.inv  where (id=${ID})" | tail -1)
	
	# extract data 
	ID=${ID}
	CUSTOMERNAME=$(echo "${RES}" | awk ' { print $2 } ')
	DATE=$(echo "${RES}" | awk ' {  print $3 } ')
	
	# show user the invoice details from 
	echo "Invoice ID: ${INVID}"
	echo "Invoice date : ${DATE}"
	echo "Customer name : ${CUSTOMERNAME}"	
	echo "Details:"
	echo "Product ID     Quantity      Unit Price     Total Product"
	echo "--------------------------------------------------------"
	
	# get invoice datails from data base and loop on it 
	mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "select * from ${MYSQLDB}.intdet where (prodID=${ID})" | while read line; do
	
		IFS=":" read -r prodID  quantity  unitPrice  <<<"${line}"
		
		# get total for each product 
		TOTAL=$((${quantity} * ${price}))
		
		# append eact total product to get total invoice 
		TOTALINV=$[${TOTALINV} + ${TOTAL}]
		
		echo "${prodID}         ${quantity}         ${unitPrice}         ${TOTAL}"
	done
	
	echo "-----------------------------------------------------------"
 	echo "Invoice total: ${TOTALINV}"
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
	
	#check use auth 
	if [ -z ${CURUSER} ]; then
		echo "Authenticate first"
		return 1
	fi
	
	#get id from user
	echo -n "Enter inv id : "
	read CUSTID
	
	# validate user input if idis integere 
	checkInt ${CUSTID}
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 1
	
	##Check if the ID is already exists or no
	checkID ${CUSTID}
	[ ${?} -ne 0 ] && echo "ID ${CUSTID} is already exists!!" && return 3
	
	#get data from user
	echo -n "Enter inv name : "
	read CUSTNAME
	echo -n "Enter invoice datw : "
	read INVDATE
	
	##Check if input is integere
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 2
	
	echo -n "Save (y/n)"
	read OPT
	
	case "${OPT}" in
	"y")
		mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "insert into ${MYSQLDB}.invdata (id,customername,date ) values (${CUSTID},${CUSTNAME},'${INVDATE}')"
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
	#check for auth 
	if [ -z ${CURUSER} ]; then
		echo "Authenticate first"
		return 1
	fi
	
	# get data from user 
	echo -n "Enter invoice id : "
	read CUSTID
	checkInt ${CUSTID}
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 2
	
	##Check if the ID is already exists or no
	checkID ${CUSTID}
	[ ${?} -eq 0 ] && echo "ID ${CUSTID} not exists!" && return 3
	
	## We used -s to disable table format
	RES=$(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -s -e "select * from ${MYSQLDB}.intdet  where (id=${CUSTID})" | tail -1)
	ID=${CUSTID}
	
	# extract data 
	NAME=$(echo "${RES}" | awk ' { print $2 } ')
	TOTAL=$(echo "${RES}" | awk ' {  print $3 } ')
	
	# show the selected invoice
	echo "Details of invoice id ${CUSTID}"
	echo "Customer name : ${NAME}"
	echo "Invoice Date : ${date }"
	
	# get conformation from user  on deleting invoice
	echo -n "Delete (y/n)"
	read OPT
	
	# action on user confomration for delete invoice
	case "${OPT}" in
	"y")
		mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "delete from ${MYSQLDB}.invdata   where id=${CUSTID}"
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
		INVNAME=$(echo ${LINE} | cut -d ":" -f 2)
		DATE=$(echo ${LINE} | cut -d ":" -f 3)

		#Execute the insert statement using mysql connection
		RES=$(
			sud mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "insert into ${MYSQLDB}.invdata (id, customername , date ) 
											values ('${ID}', '${INVNAME}', '${DATE}')"
		)
		if [ -z "${RES}" ]; then
			echo "Error can't get data"
			return 1
		else
			# Print a success message for each record inserted

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
		
		# Inert Query to database
		INSERTSTMT="INSERT INTO ${DBNAME}.intdet (id, serial, prodID , quantity , unitPrice ) 
					VALUES (${ID}, ${SERIAL}, ${PRODID}, ${QUANTITY}, ${UNITPRICE})"

		# Execute the insert statement using mysql connection
		echo "${INSERTSTMT}" | sudo mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} ${DBNAME}

		# Print a success message for each record inserted
		echo "Record inserted successfully: ${LINE}"
	done <'invdet'
}
