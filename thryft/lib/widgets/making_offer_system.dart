import 'package:flutter/material.dart';

class MakingOfferSystem extends StatefulWidget {
	final String listingName;
	final double askingPrice;
	final Future<void> Function(double offerPrice) onSubmit;

	const MakingOfferSystem({
		super.key,
		required this.listingName,
		required this.askingPrice,
		required this.onSubmit,
	});

	@override
	State<MakingOfferSystem> createState() => _MakingOfferSystemState();
}

class _MakingOfferSystemState extends State<MakingOfferSystem> {
	final _formKey = GlobalKey<FormState>();
	final _offerController = TextEditingController();
	bool _isSubmitting = false;

	@override
	void dispose() {
		_offerController.dispose();
		super.dispose();
	}

	Future<void> _handleSubmit() async {
		if (!_formKey.currentState!.validate()) return;

		final parsed = double.tryParse(_offerController.text.trim());
		if (parsed == null) return;

		setState(() => _isSubmitting = true);
		try {
			await widget.onSubmit(parsed);
			if (mounted) Navigator.of(context).pop(true);
		} finally {
			if (mounted) {
				setState(() => _isSubmitting = false);
			}
		}
	}

	@override
	Widget build(BuildContext context) {
		return SafeArea(
			child: Padding(
				padding: EdgeInsets.only(
					left: 20,
					right: 20,
					top: 20,
					bottom: MediaQuery.of(context).viewInsets.bottom + 20,
				),
				child: Form(
					key: _formKey,
					child: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								'Make an offer',
								style: Theme.of(context).textTheme.titleLarge?.copyWith(
									fontWeight: FontWeight.bold,
								),
							),
							const SizedBox(height: 8),
							Text(
								widget.listingName,
								style: Theme.of(
									context,
								).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
							),
							const SizedBox(height: 4),
							Text(
								'Listed at £${widget.askingPrice.toStringAsFixed(2)}',
								style: Theme.of(
									context,
								).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
							),
							const SizedBox(height: 16),
							TextFormField(
								controller: _offerController,
								keyboardType: const TextInputType.numberWithOptions(
									decimal: true,
								),
								decoration: const InputDecoration(
									labelText: 'Your offer (GBP)',
									prefixText: '£',
									border: OutlineInputBorder(),
								),
								validator: (value) {
									final input = value?.trim() ?? '';
									if (input.isEmpty) return 'Enter your offer amount';

									final parsed = double.tryParse(input);
									if (parsed == null) return 'Enter a valid number';
									if (parsed <= 0) return 'Offer must be greater than 0';
									if (parsed >= widget.askingPrice) {
										return 'Offer must be lower than the listed price';
									}
									return null;
								},
							),
							const SizedBox(height: 16),
							SizedBox(
								width: double.infinity,
								child: FilledButton(
									onPressed: _isSubmitting ? null : _handleSubmit,
									child: _isSubmitting
											? const SizedBox(
													height: 18,
													width: 18,
													child: CircularProgressIndicator(strokeWidth: 2),
												)
											: const Text('Send offer'),
								),
							),
						],
					),
				),
			),
		);
	}
}