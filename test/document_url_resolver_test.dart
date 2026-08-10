import 'package:daphnex_crm_mobile/core/network/document_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final runtime = Uri.parse(
    'https://runtime.example.test/wp-json/daphnex-crm/v1/',
  );

  test('rewrites LocalWP absolute URL through runtime origin', () {
    final result = DocumentUrlResolver.resolve(
      'http://daphnex-crm.local/wp-content/uploads/document.pdf?download=1',
      runtimeApiBase: runtime,
    );
    expect(
      result.toString(),
      'https://runtime.example.test/wp-content/uploads/document.pdf?download=1',
    );
  });

  test('rewrites localhost and preserves path query and fragment', () {
    final result = DocumentUrlResolver.resolve(
      'http://localhost:10003/files/document.pdf?token=opaque#page=2',
      runtimeApiBase: runtime,
    );
    expect(
      result.toString(),
      'https://runtime.example.test/files/document.pdf?token=opaque#page=2',
    );
  });

  test('rewrites loopback URL', () {
    final result = DocumentUrlResolver.resolve(
      'http://127.0.0.1/file.txt',
      runtimeApiBase: runtime,
    );
    expect(result.toString(), 'https://runtime.example.test/file.txt');
  });

  test('rewrites IPv6 loopback URL', () {
    final result = DocumentUrlResolver.resolve(
      'http://[::1]:10003/files/document.pdf?download=1#page=3',
      runtimeApiBase: runtime,
    );
    expect(
      result.toString(),
      'https://runtime.example.test/files/document.pdf?download=1#page=3',
    );
  });

  test('resolves root-relative document URL through runtime origin', () {
    final result = DocumentUrlResolver.resolve(
      '/wp-content/uploads/document.pdf?download=1',
      runtimeApiBase: runtime,
    );
    expect(
      result.toString(),
      'https://runtime.example.test/wp-content/uploads/document.pdf?download=1',
    );
  });

  test('resolves path-relative document URL through runtime origin', () {
    final result = DocumentUrlResolver.resolve(
      'wp-content/uploads/document.pdf',
      runtimeApiBase: runtime,
    );
    expect(
      result.toString(),
      'https://runtime.example.test/wp-content/uploads/document.pdf',
    );
  });

  test('leaves valid external HTTPS URL unchanged', () {
    const external = 'https://cdn.example.com/files/document.pdf?sig=opaque';
    expect(
      DocumentUrlResolver.resolve(external, runtimeApiBase: runtime).toString(),
      external,
    );
  });

  test('leaves production URL unchanged', () {
    const production = 'https://daphnex.co.uk/wp-content/document.pdf';
    expect(
      DocumentUrlResolver.resolve(
        production,
        runtimeApiBase: runtime,
      ).toString(),
      production,
    );
  });

  test('does not rewrite arbitrary local hostnames', () {
    const unexpected = 'http://unexpected.local/file.pdf?x=1#section';
    expect(
      DocumentUrlResolver.resolve(
        unexpected,
        runtimeApiBase: runtime,
      ).toString(),
      unexpected,
    );
  });

  test('rejects scheme-relative URLs', () {
    expect(
      () => DocumentUrlResolver.resolve(
        '//evil.example/path',
        runtimeApiBase: runtime,
      ),
      throwsFormatException,
    );
    expect(
      () => DocumentUrlResolver.resolve(
        '//evil.example/path?x=1',
        runtimeApiBase: runtime,
      ),
      throwsFormatException,
    );
  });

  test('does not accept non-HTTP document schemes', () {
    expect(
      () => DocumentUrlResolver.resolve(
        'javascript:alert(1)',
        runtimeApiBase: runtime,
      ),
      throwsFormatException,
    );
  });
}
