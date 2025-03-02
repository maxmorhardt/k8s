from smtplib import SMTP_SSL
from email.message import EmailMessage
import logging
import requests
import os

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

class DnsDynamicIp():
	def __init__(self, cloudflare_api_key, email_username, email_password):
		self.cloudflare_api_key = cloudflare_api_key

		self.cloudflare_base_path = 'https://api.cloudflare.com/client/v4/zones/9e72c59b01cf0700a76760983c6855a1/dns_records'
		self.headers = {"Authorization": f"Bearer {self.cloudflare_api_key}"}

	def main(self):
		records = self.__get_all_records()
		ip = self.__get_current_ip().strip()

		error_messages = []
		invalid_record_names = []
		for record in records:
			try:
				patchExecuted = self.__patch_record(record, ip)
				if patchExecuted:
					invalid_record_names.append(record['name'])
			except Exception as e:
				error_messages.append(repr(e))

		self.__send_completion_email(error_messages, invalid_record_names, ip)
					
	def __get_all_records(self):
		log.info('Getting all dns records')
		req = requests.get(self.cloudflare_base_path, headers=self.headers)
		records = req.json()['result']
		log.info(f"{records}\n")
		return records
	
	def __get_current_ip(self):
		log.info('Getting current IP')
		ip = requests.get('https://api.ipify.org').content.decode('utf8')
		log.info(f"Current IP: {ip}\n")
		return str(ip).strip()
	
	def __patch_record(self, record, ip):
		record_dns = record['name'].strip()
		log.info(f"dns: {record_dns}")
		record_ip = record['content'].strip()
		log.info(f"ip: {record_ip}")
		record_id = record['id'].strip()
		log.info(f"id: {record_id}")
		record_type = record['type'].strip()
		log.info(f"type: {record_type}")

		if record_type is not 'A':
			log.info(f"Skipping record {record_dns} with type {record_type}\n")
			return False

		if record_ip == ip:
			log.info(f"Skipping record {record_dns} with correct ip {record_ip}\n")
			return False
		else: 
			log.info(f"Record {record_dns} has ip mismatch current: {ip} - record: {record_ip}")

			is_proxed = record_dns != 'no-proxy.maxstash.io'
			req = {
				"content": f"{ip}",
				"data": {},
				"name": f"{record_dns}",
				"proxiable": True,
				"proxied": is_proxed,
				"ttl": 1,
				"type": "A",
				"zone_id": "9e72c59b01cf0700a76760983c6855a1",
				"zone_name": "maxstash.io",
				"settings": {},
				"tags": [],
				"id": f"{record_id}"
			}

			res = requests.patch(f"{self.cloudflare_base_path}/{record_id}", headers=self.headers, json=req)
			
			if res.status_code < 200 or res.status_code >= 400:
				raise Exception(f"{res.json()}")

			log.info(f"Successfully patched record {record_dns} to have ip {ip}\n")
			return True

if __name__ == "__main__":
	cloudflare_api_key = os.environ.get('CLOUDFLARE_API_KEY')

	log.info('Picked up environment variables:')
	log.info(f"cloudflare_api_key={cloudflare_api_key}")

	DnsDynamicIp(cloudflare_api_key).main()
