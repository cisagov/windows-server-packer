"""Process User Data File."""
# Third-Party Libraries
import boto3
from jinja2 import Template

ssm = boto3.client("ssm")

# Retrieve Windows Administrator Password from AWS SSM
password = ssm.get_parameter(
    Name="/windows/commando/administrator/password", WithDecryption=True
)["Parameter"]["Value"]

user_data_file_location = "./src/winrm_bootstrap.txt"
with open(user_data_file_location) as user_data_file:
    # Process the User Data File with the Windows Administrator Password
    Template(user_data_file.read()).stream(password=password).dump(
        user_data_file_location
    )
