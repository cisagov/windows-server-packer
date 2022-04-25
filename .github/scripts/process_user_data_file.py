"""Process User Data File."""
# Third-Party Libraries
import boto3
from jinja2 import Template

ssm = boto3.client("ssm")

password = ssm.get_parameter(
    Name="/windows/commando/administrator/password", WithDecryption=True
)["Parameter"]["Value"]

print("[Debugging] Password: ", password)

user_data_file_location = "./src/winrm_bootstrap.txt"
with open(user_data_file_location) as user_data_file:
    # Process user data file with the Windows Administrator password
    Template(user_data_file.read()).stream(password=password).dump(
        user_data_file_location
    )
