import os
import argparse
import logging
import operator

import yaml

from pykube import Node
from pykube import Pod
from pykube import Service
from pykube import DaemonSet

from pykube import HTTPClient
from pykube import KubeConfig

from pykube.objects import APIObject

from pykube.exceptions import KubernetesError
from pykube.exceptions import HTTPError
from pykube.exceptions import ObjectDoesNotExist


LOG = logging.getLogger('{}:{}'.format(__file__, __name__))
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))


def unserialize_from_yaml_file(path):
    with open(path, 'r') as stream:
        return yaml.load(stream)


class CassandraResourceFactory(object):
    def __init__(self, api, resource_map):
        self.api = api
        self.resource_map = resource_map

    def factory(self):
        resources = []
        for entity, def_file_path in self.resource_map:
            data = unserialize_from_yaml_file(os.path.join(PROJECT_ROOT,
                                                           def_file_path))
            resources.append(entity(self.api, data))
        return resources


class CassandraResourceController(object):
    def __init__(self, pool):
        self.pool = pool

    def create(self):
        for entity in self.pool.factory():
            try:
                entity.create()
                LOG.info('Created "{}".'.format(entity.kind))
            except HTTPError as e:
                LOG.error(e)

    def update(self):
        for entity in self.pool.factory():
            try:
                entity.update()
                LOG.info('Updated "{}".'.format(entity.kind))
            except HTTPError as e:
                LOG.error(e)

    def delete(self):
        for entity in self.pool.factory():
            try:
                entity.delete()
                LOG.info('Deleted "{}".'.format(entity.kind))
            except HTTPError as e:
                LOG.error(e)

    def validate(self):
        for entity in self.pool.factory():
            try:
                entity.validate()
            except (KubernetesError, ObjectDoesNotExist) as e:
                print('✘ {}: {}'.format(entity.kind, e))
            else:
                print('✔ {}'.format(entity.kind))


class K8SResource(APIObject):
    @property
    def labels(self):
        return self.obj['metadata']['labels']

    def _labels_to_string(self):
        return ' '.join(['{}={}'.format(k, v) for k, v in self.labels.items()])

    def delete(self):
        # Original method ignores 404 code for some reason, but we don't.
        r = self.api.delete(**self.api_kwargs())
        self.api.raise_for_status(r)

    def validate(self):
        LOG.debug('Check that object exists on server.')
        self.exists(ensure=True)


class CassandraDaemonSet(K8SResource, DaemonSet):
    pods_required = 3
    nodes_required = 3

    def _require_nodes(self, expected):
        nodes = self._get_nodes()
        actual = len(nodes)
        if actual < expected:
            raise KubernetesError(
                'Expected {} nodes with "{}" labels. '
                'Actual {}.'.format(expected,
                                    self._labels_to_string(),
                                    actual))
        return nodes

    def _require_pods(self, expected):
        pods = self._get_pods()
        active_pods = [p for p in pods if operator.attrgetter('ready')]
        actual = len(active_pods)
        if actual < expected:
            raise KubernetesError(
                'Expected {} active pods with "{}" labels. '
                'Actual {}.'.format(expected,
                                    self._labels_to_string(),
                                    actual))
        return pods

    def _get_nodes(self):
        return Node.objects(self.api).filter(selector=self.labels)

    def _get_pods(self):
        return Pod.objects(self.api).filter(selector=self.labels)

    def create(self):
        nodes = self._require_nodes(self.nodes_required)
        for ct in self.obj['spec']['template']['spec']['containers']:
            if ct['name'] == 'cassandra':
                ct['env'].append({'name': 'CASSANDRA_SEEDS',
                                  'value': ','.join([n.name for n in nodes])})
                break
        super().create()

    def delete(self):
        super(CassandraDaemonSet, self).delete()
        pods = self._get_pods()
        LOG.debug('Cascade delete {} pods '
                  'labeled with "{}'.format(len(pods),
                                            self._labels_to_string()))
        for pod in pods:
            pod.delete()

    def validate(self):
        super().validate()

        LOG.debug('Check that at least {} '
                  'nodes exists.'.format(self.nodes_required))
        self._require_nodes(self.nodes_required)

        LOG.debug('Check that at least {} '
                  'pods exists.'.format(self.pods_required))
        self._require_pods(self.pods_required)


class CassandraService(K8SResource, Service):
    pass


def parse_args():
    parser = argparse.ArgumentParser(description='Yagoda cassandra '
                                                 'management tool.')
    parser.add_argument('action', choices=['create', 'update',
                                           'delete', 'validate'])
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-d', '--debug', action='store_true')
    group.add_argument('-v', '--verbose', action='store_true')
    group.add_argument('-q', '--quiet', action='store_true')
    return parser.parse_args()


def setup_logging(log_level):
    log_format = '%(asctime)s ' + __file__ \
                 + '[%(process)d] %(levelname)s: %(message)s'
    logging.basicConfig(level=log_level, format=log_format)


def main():
    args = parse_args()

    if args.debug:
        log_level = logging.DEBUG
    elif args.verbose:
        log_level = logging.INFO
    elif args.quiet:
        log_level = logging.CRITICAL
    else:
        log_level = logging.WARNING
    setup_logging(log_level)

    api = HTTPClient(KubeConfig.from_file(os.environ['KUBECONFIG']))
    resource_map = (
        (CassandraDaemonSet, 'cassandra/k8s/daemonset.yaml'),
        (CassandraService, 'cassandra/k8s/service.yaml'),
        (CassandraService, 'cassandra/k8s/peer-service.yaml')
    )
    pool = CassandraResourceFactory(api, resource_map)
    ctl = CassandraResourceController(pool)
    if args.action == 'create':
        ctl.create()
    if args.action == 'update':
        ctl.update()
    elif args.action == 'delete':
        ctl.delete()
    elif args.action == 'validate':
        ctl.validate()


if __name__ == '__main__':
    main()
