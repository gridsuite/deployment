#
# Copyright (c) 2020, RTE (http://www.rte-france.com)
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
import sys
import yaml
import requests


def parse_image(image):
    colon_split = image.split(':')
    repository = colon_split[0]
    tag = 'latest'
    if len(colon_split) == 2:
        tag = colon_split[1]

    slash_split = repository.split('/')
    registry = 'docker.io'
    if len(slash_split) == 3:
        registry = slash_split[0]
        repository = '/'.join(slash_split[1:3])

    return (registry, repository, tag)


def get_token(repository):
    response = requests.get(f'https://auth.docker.io/token?service=registry.docker.io&scope=repository:{repository}:pull')
    if response.ok:
        return response.json()['token']
    else:
        response.raise_for_status()


def get_digest(repository, tag, token):
    headers = {'Authorization': f'Bearer {token}', 'Accept': 'application/vnd.docker.distribution.manifest.v2+json'}
    response = requests.head(f'https://index.docker.io/v2/{repository}/manifests/{tag}', headers=headers)
    if response.ok:
        return response.headers['Docker-Content-Digest']
    else:
        response.raise_for_status()

def update_images(containers):
    for container in containers:
        image = container['image']

        # parse image and get tag
        (registry, repository, tag) = parse_image(image)

        # get digest from tag (only works with docker.io)
        if registry == 'docker.io':
            token = get_token(repository)
            digest = get_digest(repository, tag, token)
            # replace tag by digest
            container['image'] = repository + '@' + digest

documents = list(yaml.load_all(sys.stdin.read(), Loader=yaml.FullLoader))
for document in documents:
    if 'spec' in document:
        spec = document['spec']
        if 'template' in spec:
            containers = spec['template']['spec']['containers']
            update_images(containers)
        if 'jobTemplate' in spec:
            containers = spec['jobTemplate']['spec']['template']['spec']['containers']
            update_images(containers)

print(yaml.dump_all(documents))
